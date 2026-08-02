#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<EOF
FLOWCAST_VERSION=0.1.0-rc.6
FLOWCAST_DOCKER_GID=999
ICECAST_SOURCE_PASSWORD=source-test-only
ICECAST_RELAY_PASSWORD=relay-test-only
ICECAST_ADMIN_PASSWORD=admin-test-only
EOF
plain="$(docker compose --env-file "$tmp" -f "$ROOT/compose.yml" config)"
enabled="$(docker compose --env-file "$tmp" -f "$ROOT/compose.yml" -f "$ROOT/compose.docker-control.yml" config)"
grep -q 'ICECAST_HOST: icecast' <<<"$plain"
grep -q 'ICECAST_PORT: "8000"' <<<"$plain"
[[ "$(grep -c 'source-test-only' <<<"$plain")" -eq 2 ]]
grep -q '/var/run/docker.sock' <<<"$enabled"
! grep -q '/var/run/docker.sock' <<<"$plain"
! rg -q 'ICECAST_MOUNT|source-test-only' "$ROOT"/config.yml 2>/dev/null
echo 'RC6 Compose contracts passed (secrets redacted).'
