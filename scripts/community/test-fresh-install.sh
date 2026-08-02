#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VERSION="${1:-$(cat "$ROOT/VERSION")}"; RELEASE_BASE_URL="${FLOWCAST_RELEASE_BASE_URL:-}"
[[ -n "$RELEASE_BASE_URL" ]] || { echo 'Set FLOWCAST_RELEASE_BASE_URL to a release asset directory URL.' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; HOME_DIR="$(mktemp -d)"; trap 'rm -rf "$HOME_DIR"' EXIT
"$ROOT/install.sh" --version "$VERSION" --install-dir "$HOME_DIR/flowcast" --release-base-url "$RELEASE_BASE_URL" --no-start --non-interactive
for file in compose.yml compose.docker-control.yml .env images.lock release-manifest.json; do [[ -f "$HOME_DIR/flowcast/$file" ]] || { echo "missing $file" >&2; exit 1; }; done
docker compose --env-file "$HOME_DIR/flowcast/.env" -f "$HOME_DIR/flowcast/compose.yml" config --quiet
grep -q '^FLOWCAST_DOCKER_CONTROL_ENABLED=true$' "$HOME_DIR/flowcast/.env"
grep -q '^FLOWCAST_DOCKER_SOCKET=' "$HOME_DIR/flowcast/.env"
grep -q '^FLOWCAST_DOCKER_GID=' "$HOME_DIR/flowcast/.env"
rendered="$(docker compose --env-file "$HOME_DIR/flowcast/.env" -f "$HOME_DIR/flowcast/compose.yml" -f "$HOME_DIR/flowcast/compose.docker-control.yml" config)"
grep -q 'ICECAST_HOST: icecast' <<<"$rendered"
grep -q 'ICECAST_PORT: "8000"' <<<"$rendered"
source_secret="$(sed -n 's/^ICECAST_SOURCE_PASSWORD=//p' "$HOME_DIR/flowcast/.env")"
[[ "$(grep -cF "$source_secret" <<<"$rendered")" -eq 2 ]]
if grep -RqF "$source_secret" "$HOME_DIR/flowcast" --include=config.yml; then
  echo "source password leaked into config.yml" >&2
  exit 1
fi
echo "Fresh-install packaging check passed in temporary storage (no full qualification)."
