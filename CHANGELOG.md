# Changelog

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
