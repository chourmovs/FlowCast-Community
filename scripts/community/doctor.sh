#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
usage() { echo "Usage: doctor.sh [--install-dir DIR] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="$2"; shift 2;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for cmd in docker df curl; do need "$cmd"; done
require_install
docker info >/dev/null 2>&1 || die "Docker daemon is unavailable"
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is unavailable"
compose config --quiet
load_env
for file in compose.yml compose.docker-control.yml .env images.lock release-manifest.json; do [[ -f "$FLOWCAST_HOME/$file" ]] || die "Missing $FLOWCAST_HOME/$file"; done
df -Pk "$FLOWCAST_HOME" | awk 'NR==2 && $4 < 1048576 {exit 1}' || die "Less than 1 GiB free disk remains"
for port in "${FLOWCAST_HTTP_PORT:-8080}" "${FLOWCAST_STREAM_PORT:-8010}"; do log "Configured host port: $port"; done
for image in control engine analyzer bliss icecast; do docker image inspect "ghcr.io/chourmovs/flowcast-$image:${FLOWCAST_VERSION}" >/dev/null 2>&1 || die "Missing image: flowcast-$image:${FLOWCAST_VERSION}"; done
failed=false
for service in storage-init icecast bliss audio-daemon engine control; do
  id="$(compose ps -q "$service")"; [[ -n "$id" ]] || { log "$service: missing"; failed=true; continue; }
  status="$(docker inspect -f '{{.State.Status}}{{if .State.Health}}/{{.State.Health.Status}}{{end}}' "$id")"; log "$service: $status"
done
curl -fsS "http://localhost:${FLOWCAST_HTTP_PORT:-8080}/api/health" >/dev/null || { log "Control health endpoint failed"; failed=true; }
curl -fsS "http://localhost:${FLOWCAST_STREAM_PORT:-8010}/status-json.xsl" >/dev/null || { log "Icecast status endpoint failed"; failed=true; }
compose ps
[[ "$failed" == false ]] || die "One or more diagnostics failed"
log "Diagnostics passed; secret values were intentionally omitted."
