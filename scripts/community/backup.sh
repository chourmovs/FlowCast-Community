#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
OUTPUT="${FLOWCAST_BACKUP_DIR:-$PWD/backups}"
usage() { echo "Usage: backup.sh [--install-dir DIR] [--output DIR] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="$2"; shift 2;; --output) OUTPUT="$2"; shift 2;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for cmd in docker tar; do need "$cmd"; done; require_install
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"; DEST="$OUTPUT/flowcast-backup-$STAMP.tar.gz"; run mkdir -p "$OUTPUT"
run compose stop
if [[ "$DRY_RUN" == false ]]; then docker run --rm -v flowcast_flowcast-data:/data:ro -v "$OUTPUT:/backup" alpine:3.20 tar -czf "/backup/$(basename "$DEST")" -C /data .; fi
run compose start
log "Backup created: $DEST (configuration and media excluded)"
