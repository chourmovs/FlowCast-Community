#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
BACKUP=""
usage() { echo "Usage: restore.sh --backup FILE [--install-dir DIR] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --backup) BACKUP="$2"; shift 2;; --install-dir) FLOWCAST_HOME="$2"; shift 2;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ -f "$BACKUP" ]] || die "Backup file not found"; for cmd in docker tar; do need "$cmd"; done; require_install
tar -tzf "$BACKUP" >/dev/null || die "Invalid backup archive"; run compose stop
if [[ "$DRY_RUN" == false ]]; then
  stage="$(mktemp -d)"; trap 'rm -rf "$stage"' EXIT; tar -xzf "$BACKUP" -C "$stage"
  for volume in flowcast-catalog flowcast-media flowcast-settings flowcast-engine-history flowcast-analysis; do
    [[ -d "$stage/$volume" ]] || continue
    docker run --rm -v "flowcast_$volume:/data" -v "$stage/$volume:/backup:ro" alpine:3.20 sh -c 'rm -rf /data/* /data/.[!.]* /data/..?* 2>/dev/null || true; cp -a /backup/. /data/'
  done
fi
run compose start
log "Restore complete"
