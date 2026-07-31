#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
BACKUP=""
usage() { echo "Usage: restore.sh --backup FILE [--install-dir DIR] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --backup) BACKUP="$2"; shift 2;; --install-dir) FLOWCAST_HOME="$2"; shift 2;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ -f "$BACKUP" ]] || die "Backup file not found"; for cmd in docker tar; do need "$cmd"; done; require_install
tar -tzf "$BACKUP" >/dev/null || die "Invalid backup archive"; run compose stop
if [[ "$DRY_RUN" == false ]]; then docker run --rm -v flowcast_flowcast-data:/data -v "$(dirname "$BACKUP"):/backup:ro" alpine:3.20 sh -c 'rm -rf /data/* && tar -xzf "/backup/$1" -C /data' sh "$(basename "$BACKUP")"; fi
run compose start
log "Restore complete"
