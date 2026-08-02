#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
VERSION=""; ENABLE_DOCKER_CONTROL=false
usage() { echo "Usage: update.sh --version VERSION [--install-dir DIR] [--enable-docker-control] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --version) VERSION="$2"; shift 2;; --install-dir) FLOWCAST_HOME="$2"; shift 2;; --enable-docker-control) ENABLE_DOCKER_CONTROL=true; shift;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ -n "$VERSION" ]] || die "--version is required"; need docker; require_install
run cp "$FLOWCAST_HOME/.env" "$FLOWCAST_HOME/.env.pre-update"
load_env
docker_control="${FLOWCAST_DOCKER_CONTROL_ENABLED:-false}"
if [[ "$ENABLE_DOCKER_CONTROL" == true ]]; then docker_control=true; fi
if [[ "$docker_control" == true ]]; then
  socket=/var/run/docker.sock; [[ "${DOCKER_HOST:-}" == unix://* ]] && socket="${DOCKER_HOST#unix://}"
  [[ -S "$socket" && -r "$socket" && -w "$socket" ]] || die "Docker Control is active but $socket is not an accessible Unix socket."
  gid="$(stat -c '%g' "$socket" 2>/dev/null)" || die "Cannot determine Docker socket GID"
  [[ -f "$FLOWCAST_HOME/compose.docker-control.yml" ]] || die "Docker Control is active but compose.docker-control.yml is missing"
elif [[ "$ENABLE_DOCKER_CONTROL" == false ]]; then
  log "Docker Control remains disabled (RC5 safety). To enable root-equivalent socket access, rerun with --enable-docker-control."
fi
if [[ "$DRY_RUN" == false ]]; then
  sed -i "s/^FLOWCAST_VERSION=.*/FLOWCAST_VERSION=${VERSION#v}/" "$FLOWCAST_HOME/.env"
  if [[ "$ENABLE_DOCKER_CONTROL" == true ]]; then sed -i 's/^FLOWCAST_DOCKER_CONTROL_ENABLED=.*/FLOWCAST_DOCKER_CONTROL_ENABLED=true/' "$FLOWCAST_HOME/.env"; fi
  if [[ "$docker_control" == true ]]; then
    sed -i '/^FLOWCAST_DOCKER_SOCKET=/d;/^FLOWCAST_DOCKER_GID=/d;/^ICECAST_MOUNT=/d' "$FLOWCAST_HOME/.env"
    printf 'FLOWCAST_DOCKER_SOCKET=%s\nFLOWCAST_DOCKER_GID=%s\n' "$socket" "$gid" >>"$FLOWCAST_HOME/.env"
  else sed -i '/^ICECAST_MOUNT=/d' "$FLOWCAST_HOME/.env"; fi
  chmod 600 "$FLOWCAST_HOME/.env"
fi
run compose pull
run compose up -d --force-recreate control engine
if [[ "$DRY_RUN" == false ]]; then
  compose up -d --wait --wait-timeout "${FLOWCAST_START_TIMEOUT:-300}"
fi
log "Updated to ${VERSION#v}; see docs/community/update-rollback.md for rollback."
