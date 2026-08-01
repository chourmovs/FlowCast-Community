#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
OUTPUT="${FLOWCAST_BACKUP_DIR:-$PWD/backups}"; INCLUDE_MEDIA=false
usage() { echo "Usage: backup.sh [--install-dir DIR] [--output DIR] [--include-media] [--dry-run]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="$2"; shift 2;; --output) OUTPUT="$2"; shift 2;; --include-media) INCLUDE_MEDIA=true; shift;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for cmd in docker tar; do need "$cmd"; done; require_install
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"; DEST="$OUTPUT/flowcast-backup-$STAMP.tar.gz"; run mkdir -p "$OUTPUT"
run compose stop
if [[ "$DRY_RUN" == false ]]; then
  stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT
  cp "$FLOWCAST_HOME/.env" "$FLOWCAST_HOME/compose.yml" "$FLOWCAST_HOME/compose.docker-control.yml" "$stage/"
  volumes=(flowcast-catalog flowcast-settings flowcast-engine-history flowcast-analysis)
  if [[ "$INCLUDE_MEDIA" == true ]]; then
    volumes+=(flowcast-media)
  else
    log "Media are excluded by default; use --include-media for a potentially large archive."
  fi
  for volume in "${volumes[@]}"; do mkdir -p "$stage/$volume"; docker run --rm -v "flowcast_$volume:/source:ro" -v "$stage/$volume:/backup" alpine:3.20 sh -c 'cp -a /source/. /backup/'; done
  tar -czf "$DEST" -C "$stage" .
fi
run compose start
log "Backup created: $DEST"
