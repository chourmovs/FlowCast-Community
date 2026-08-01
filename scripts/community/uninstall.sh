#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
PURGE=false
usage() { echo "Usage: uninstall.sh [--install-dir DIR] [--purge-data] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="$2"; shift 2;; --purge-data) PURGE=true; shift;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
need docker; require_install; run compose down
if [[ "$PURGE" == true ]]; then run compose down --volumes; run rm -rf -- "$FLOWCAST_HOME"; else log "Data retained at $FLOWCAST_HOME"; fi
