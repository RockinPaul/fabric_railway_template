# Fabric on Railway

Self-host [Fabric](https://github.com/danielmiessler/fabric)'s REST API, with
its library of reusable AI prompts (Fabric calls them patterns) bundled in.

This repository holds **only the Railway glue**. It is not a fork of Fabric.
The Dockerfile builds a pinned upstream version from source, because upstream
publishes no container image.

## Layout

| File | Purpose |
|---|---|
| `Dockerfile` | Clones the pinned Fabric tag, applies the patch, builds the binary |
| `entrypoint.sh` | Seeds the config volume, writes Railway variables into Fabric's `.env`, drops privileges |
| `patches/` | Three small changes upstream has not taken yet |
| `railway.json` | Healthcheck and restart policy, so they live with the code |
| `TEMPLATE_OVERVIEW.md` | The marketplace description |

## Bumping Fabric

Change two lines at the top of the `Dockerfile`:

```dockerfile
ARG FABRIC_VERSION=v1.4.478
ARG FABRIC_COMMIT=b682dad740f24e85ce9a48d23babc6780dd476ac
```

Take the commit from `git ls-remote --tags https://github.com/danielmiessler/fabric.git`.
The build asserts it, so a moved or re-pointed tag fails loudly instead of
silently shipping something else.

Two things can break on a bump, and both fail the build rather than passing
quietly:

- **The patch may no longer apply.** `git apply` stops the build. Rebase it
  against the new tag, or delete the hunk if upstream has taken the change.
- **The Go toolchain may be too old.** Check upstream's `go.mod`; the
  `GO_IMAGE` argument selects the builder image.

## The patch, and why each piece exists

- **An unauthenticated `/health` route.** Railway's health check is a plain GET
  with no headers, and Fabric protects everything except its Swagger routes.
- **`text/event-stream` on the streaming chat endpoint.** Upstream sends
  `text/readystream`, which is not a real media type, while its own API
  annotation says otherwise. Browser `EventSource` clients need the correct one.
- **A configurable CORS origin.** Upstream pins the allowed origin to
  `http://localhost:5173`, so no browser client on a deployed domain can read
  the stream. It now comes from `FABRIC_ALLOWED_ORIGIN`, defaulting to `*`,
  which is safe because the API authenticates with the `X-API-Key` header
  rather than cookies.

All three are worth sending upstream. If they land, this directory shrinks.

## Variables

| Variable | Required | Purpose |
|---|---|---|
| `FABRIC_API_KEY` | yes | Sent as `X-API-Key`. The container refuses to start without it, and so does Fabric on a public address |
| Provider credential | yes in practice | One of `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` and others, matching `DEFAULT_VENDOR`. Without one the server starts and answers health checks, but every completion fails, so the entrypoint warns loudly |
| `DEFAULT_VENDOR` | no | Defaults to `OpenAI` |
| `DEFAULT_MODEL` | no | Defaults to `gpt-4.1-mini` |
| `FABRIC_ALLOWED_ORIGIN` | no | CORS origin for browser clients, defaults to `*` |

The entrypoint passes roughly forty provider and helper variables through to
Fabric's `.env` when they are set. See `entrypoint.sh` for the full list.

## Notes for operators

- **Attach a volume at `/home/appuser/.config/fabric`.** Patterns, strategies,
  sessions, contexts and the generated `.env` all live there. A Railway volume
  root contains a root-owned `lost+found`; the entrypoint runs its setup as
  root before dropping privileges, so that is harmless here.
- **Provider keys are written to that volume in plain text**, because that is
  how Fabric reads its configuration. Anyone with volume access can read them.
- **Swagger is deliberately unauthenticated**, which is upstream's choice. Your
  API surface is publicly readable at `/swagger/index.html`; the endpoints
  behind it are not.

## Licenses

The glue in this repository is MIT licensed, see `LICENSE`. The files under
`patches/` are diffs against Fabric's source and are therefore covered by
Fabric's own MIT license. Fabric itself is MIT.

## History

Before 2026-09-10 this repository was a full fork of Fabric, pinned at
v1.4.451, carrying the same changes as direct edits to upstream's Go source.
The fork's last commit was `208786d32cf5664f37bb4df25ffdda9e4ed62184`. It was replaced by this thin layout so
that bumping Fabric is a two-line change rather than a merge.
