#!/usr/bin/env bash
set -euo pipefail
FLOWCAST_HOME="${FLOWCAST_HOME:-/opt/flowcast}"
DRY_RUN="${DRY_RUN:-false}"
log() { printf '[flowcast] %s\n' "$*"; }
die() { printf '[flowcast] ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }
run() { if [[ "$DRY_RUN" == true ]]; then printf '+ '; printf '%q ' "$@"; printf '\n'; else "$@"; fi; }
compose() { docker compose --project-directory "$FLOWCAST_HOME" --env-file "$FLOWCAST_HOME/.env" -f "$FLOWCAST_HOME/compose.yml" "$@"; }
require_install() { [[ -f "$FLOWCAST_HOME/compose.yml" && -f "$FLOWCAST_HOME/.env" ]] || die "No installation at $FLOWCAST_HOME"; }
