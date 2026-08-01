#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-0.1.0-rc.2}"; RELEASE_BASE_URL="${FLOWCAST_RELEASE_BASE_URL:-}"
[[ -n "$RELEASE_BASE_URL" ]] || { echo 'Set FLOWCAST_RELEASE_BASE_URL to a release asset directory URL.' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; HOME_DIR="$(mktemp -d)"; trap 'rm -rf "$HOME_DIR"' EXIT
"$ROOT/install.sh" --version "$VERSION" --install-dir "$HOME_DIR/flowcast" --release-base-url "$RELEASE_BASE_URL" --no-start --non-interactive
for file in compose.yml compose.docker-control.yml .env images.lock release-manifest.json; do [[ -f "$HOME_DIR/flowcast/$file" ]] || { echo "missing $file" >&2; exit 1; }; done
docker compose --env-file "$HOME_DIR/flowcast/.env" -f "$HOME_DIR/flowcast/compose.yml" config --quiet
if grep -q '^FLOWCAST_DOCKER_CONTROL_ENABLED=true$' "$HOME_DIR/flowcast/.env"; then docker compose --env-file "$HOME_DIR/flowcast/.env" -f "$HOME_DIR/flowcast/compose.yml" -f "$HOME_DIR/flowcast/compose.docker-control.yml" config --quiet; fi
echo "Fresh-install packaging check passed in temporary storage (no full qualification)."
