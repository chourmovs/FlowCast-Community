# Runtime contract

[Repository home](../../README.md) · [Documentation index](../README.md)
The canonical distribution has six Compose services: `storage-init`, `icecast`, `bliss`, `audio-daemon`, `engine`, and `control`. The public HTTP mapping targets control port 8088; Bliss listens on 8090; Icecast listens on 8000. `audio-daemon` uses the analyzer OCI image but is never named `analyzer` as a Compose service.

Persistent state is separated into `flowcast-catalog`, `flowcast-media`, `flowcast-settings`, `flowcast-engine-history`, `flowcast-cache`, `flowcast-analysis`, and `flowcast-runtime-state`. Control and engine share `/flowcast` and `/data/engine_history`; engine writes runtime state through `/tmp`, while control reads the same volume at `/runtime-state` read-only. Both control and engine wait for a successful `storage-init`. Retired `/media`, `/settings`, `/history`, `/analysis`, 8091, and 8092 contracts are forbidden by the runtime audit.

The public manifest mirrors the six-service distribution boundary without containing private source. The five public image names, entrypoint commands, environment keys, dependencies, health checks, and volume targets are enforced by `scripts/audit-runtime-contract.py`. The engine image's `flowcast-engine --healthcheck` is authoritative: it validates playing state, Icecast connection and mount confirmation, authentication errors, and health-state freshness after a 120-second bootstrap grace period.

Docker socket access is absent from the base manifest. The explicit `compose.docker-control.yml` override mounts the host (including rootless `DOCKER_HOST=unix://…`) Unix socket and adds the socket's detected numeric GID to the non-root control process. Installation then pings Docker and resolves the current project and engine by Compose labels without changing engine state.
