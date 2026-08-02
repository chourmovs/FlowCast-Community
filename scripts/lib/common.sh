#!/usr/bin/env bash
set -euo pipefail
FLOWCAST_HOME="${FLOWCAST_HOME:-/opt/flowcast}"
DRY_RUN="${DRY_RUN:-false}"
log() { printf '[flowcast] %s\n' "$*"; }
die() { printf '[flowcast] ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }
run() { if [[ "$DRY_RUN" == true ]]; then printf '+ '; printf '%q ' "$@"; printf '\n'; else "$@"; fi; }
load_env() {
  local key value
  [[ -f "$FLOWCAST_HOME/.env" ]] || die "Missing $FLOWCAST_HOME/.env"
  while IFS='=' read -r key value; do
    case "$key" in FLOWCAST_VERSION|FLOWCAST_HTTP_PORT|FLOWCAST_STREAM_PORT|FLOWCAST_DOCKER_CONTROL_ENABLED|FLOWCAST_DOCKER_SOCKET|FLOWCAST_DOCKER_GID|FLOWCAST_PUBLIC_URL) printf -v "$key" '%s' "$value" ;; esac
  done < "$FLOWCAST_HOME/.env"
}
build_compose_files() {
  load_env
  compose_files=(-f "$FLOWCAST_HOME/compose.yml")
  if [[ "${FLOWCAST_DOCKER_CONTROL_ENABLED:-false}" == true ]]; then
    [[ -f "$FLOWCAST_HOME/compose.docker-control.yml" ]] || die "Docker control is enabled but compose.docker-control.yml is missing"
    compose_files+=(-f "$FLOWCAST_HOME/compose.docker-control.yml")
  fi
}
compose() { build_compose_files; docker compose --project-directory "$FLOWCAST_HOME" --env-file "$FLOWCAST_HOME/.env" "${compose_files[@]}" "$@"; }
require_install() { [[ -f "$FLOWCAST_HOME/compose.yml" && -f "$FLOWCAST_HOME/.env" ]] || die "No installation at $FLOWCAST_HOME"; }
