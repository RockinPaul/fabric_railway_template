# Fabric on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/fabric?referralCode=YqmMB-&utm_medium=integration&utm_source=template&utm_campaign=generic)

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
| `patches/` | One small change upstream has not taken yet |
| `railway.json` | Healthcheck and restart policy, so they live with the code |
| `TEMPLATE_OVERVIEW.md` | The marketplace description |

## Bumping Fabric

Change two lines at the top of the `Dockerfile`:

```dockerfile
ARG FABRIC_VERSION=v1.4.518
ARG FABRIC_COMMIT=177b3a9d284895c907d6eb3a64937d174add4cd5
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

## The patch, and why it exists

- **An unauthenticated `/health` route.** Railway's health check is a plain GET
  with no headers, and Fabric protects everything except its Swagger routes.

It is worth sending upstream. Until v1.4.518 the patch also carried the
`text/event-stream` media type for the streaming chat endpoint and a
configurable CORS origin; upstream took both (v1.4.510 and v1.4.508), so they
were dropped.

## Variables

| Variable | Required | Purpose |
|---|---|---|
| `FABRIC_API_KEY` | yes | Sent as `X-API-Key`. The container refuses to start without it, and so does Fabric on a public address |
| Provider credential | yes in practice | One of `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` and others, matching `DEFAULT_VENDOR`. Without one the server starts and answers health checks, but every completion fails, so the entrypoint warns loudly |
| `DEFAULT_VENDOR` | no | Defaults to `OpenAI` |
| `DEFAULT_MODEL` | no | Defaults to `gpt-4.1-mini` |
| `FABRIC_CORS_ORIGINS` | no | Browser origins allowed to call the API, comma-separated, defaults to `*`. The older `FABRIC_ALLOWED_ORIGIN` is still read when this is unset. `*` is safe because the API authenticates with the `X-API-Key` header rather than cookies |

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
