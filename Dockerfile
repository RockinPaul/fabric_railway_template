# syntax=docker/dockerfile:1
#
# Railway-ready Fabric REST API.
#
# This repository is NOT a fork of Fabric. It holds only the Railway glue and
# builds a pinned upstream version from source, because upstream publishes no
# container image. Bumping Fabric is a two-line change: FABRIC_VERSION and
# FABRIC_COMMIT below.

ARG FABRIC_VERSION=v1.4.478
# The tag's commit, asserted after the clone so a moved or re-pointed tag fails
# the build instead of silently changing what ships.
ARG FABRIC_COMMIT=b682dad740f24e85ce9a48d23babc6780dd476ac
# Upstream's go.mod requires this toolchain; a bump may need a newer one.
ARG GO_IMAGE=golang:1.26-alpine
ARG ALPINE_VERSION=3.21

FROM ${GO_IMAGE} AS builder

ARG FABRIC_VERSION
ARG FABRIC_COMMIT
WORKDIR /build

RUN apk add --no-cache git ca-certificates

RUN git clone --depth 1 --branch "${FABRIC_VERSION}" https://github.com/danielmiessler/fabric.git src \
    && actual="$(git -C src rev-parse HEAD)" \
    && if [ "$actual" != "${FABRIC_COMMIT}" ]; then \
         echo "tag ${FABRIC_VERSION} is at ${actual}, expected ${FABRIC_COMMIT}" >&2; exit 1; \
       fi

# Three small changes upstream has not taken yet: an unauthenticated /health
# route for the platform health check, the correct SSE media type, and a CORS
# origin that is not pinned to a local dev server. git apply fails the build if
# upstream has moved, which is the signal to rebase or drop the patch.
COPY patches/ /patches/
RUN git -C src apply --verbose /patches/*.patch

RUN cd src \
    && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /fabric ./cmd/fabric

FROM alpine:${ALPINE_VERSION}

LABEL org.opencontainers.image.description="Railway-ready Fabric REST API."
LABEL org.opencontainers.image.source="https://github.com/RockinPaul/fabric_railway_template"

# yt-dlp powers Fabric's YouTube helpers; su-exec drops privileges after the
# entrypoint has written config into the volume as root.
RUN apk add --no-cache ca-certificates python3 py3-pip su-exec \
    && pip3 install --no-cache-dir --break-system-packages 'setuptools>=78.1.1' \
    && pip3 install --no-cache-dir --break-system-packages 'yt-dlp>=2026.02.21' \
    && apk upgrade --no-cache \
    && adduser -D appuser \
    && mkdir -p /home/appuser/.config/fabric /usr/local/share/fabric \
    && chown -R appuser:appuser /home/appuser/.config

COPY --from=builder /fabric /usr/local/bin/fabric
# Patterns and strategies are seeded into the volume on first boot, so the
# deployment works offline instead of cloning them at runtime. docs/ carries
# swagger.yaml, which the server looks for next to its own binary.
COPY --from=builder /build/src/data/patterns /usr/local/share/fabric/patterns
COPY --from=builder /build/src/data/strategies /usr/local/share/fabric/strategies
COPY --from=builder /build/src/docs /usr/local/bin/docs
COPY --chmod=755 entrypoint.sh /usr/local/bin/railway-start

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/railway-start"]
