# Changelog

## 2026-10-14

- **Fabric bumped from v1.4.478 to v1.4.518**, pinned by tag and asserted by
  commit (`177b3a9d284895c907d6eb3a64937d174add4cd5`). Upstream security fixes
  in this range include a remote arbitrary file write through the
  `create_coding_feature` pattern, stricter path containment for file changes,
  and server hardening: patterns run through the REST API may only use the
  text and datetime plugins, network fetches are limited to public addresses,
  sessions are written atomically with private permissions.
- **The patch shrank to the `/health` route.** Upstream now sends
  `text/event-stream` on the streaming chat endpoint (v1.4.510) and has its own
  CORS support (v1.4.508), so those two hunks were dropped.
- **CORS is upstream's now, and browser clients work.** The template's old
  hunk set `Access-Control-Allow-Origin` only on the chat response, so a
  browser's preflight request, which carries no `X-API-Key`, got 401 and no
  browser client could call the API. Upstream answers preflight before the key
  check. Set `FABRIC_CORS_ORIGINS` (comma-separated); the entrypoint maps the
  old `FABRIC_ALLOWED_ORIGIN` onto it and defaults to `*` as before, which
  Fabric now logs as a warning at startup.
- **The API key is no longer on the command line.** Fabric reads
  `FABRIC_API_KEY` from the environment, so the entrypoint stops passing
  `--api-key`, which put the key in the process list.
- **Optional-key providers need their base URL.** Ollama and LM Studio are
  only activated when `OLLAMA_URL` or `LM_STUDIO_API_BASE_URL` is set; the
  entrypoint already passes both through.

### Upgrading an existing deployment

Nothing to change. The config volume is read as before; patterns and
strategies already seeded there are kept. If you set `FABRIC_ALLOWED_ORIGIN`,
it keeps working; `FABRIC_CORS_ORIGINS` takes precedence when both are set.

## 2026-09-10

Replaced the fork with a thin template repository.

- **The repository no longer contains Fabric's source.** It was a full fork of
  upstream (about 190 MB) pinned at v1.4.451, with the Railway changes applied
  as direct edits to upstream's Go files. It is now a Dockerfile, an entrypoint,
  one patch file and the docs. Previous head: `208786d32cf5664f37bb4df25ffdda9e4ed62184`.
- **Fabric bumped from v1.4.451 to v1.4.478**, pinned by tag and asserted by
  commit. This picks up two upstream security improvements: Fabric now refuses
  to bind a non-loopback address without an API key, and it compares API keys
  as digests in constant time rather than comparing the raw values.
- **The build now uses `golang:1.26-alpine`.** Upstream's `go.mod` requires Go
  1.26, so the previous hand-downloaded Go 1.25.9 could not have built it.
- **CORS origin is configurable** through `FABRIC_ALLOWED_ORIGIN` instead of
  being pinned to `http://localhost:5173`, which blocked every browser client
  on a deployed domain.
- **The entrypoint refuses to start with an empty `FABRIC_API_KEY`** and
  explains why, rather than letting Fabric fail with a terser message.
- **The entrypoint warns when no provider credential is set**, which previously
  produced a deployment that passed health checks but failed every completion.
- **Config writes no longer use `sed` in place**, so a key or base URL
  containing a slash or backslash cannot corrupt Fabric's `.env`.
- **The marketplace description is now version controlled** in
  `TEMPLATE_OVERVIEW.md`. It previously existed only on Railway, where four of
  its example URLs had been published as `https:///health` because the
  marketplace strips `<angle-bracket>` placeholders as HTML. Those are repaired.
