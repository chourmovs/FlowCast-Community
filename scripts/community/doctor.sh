#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
usage() { echo "Usage: doctor.sh [--install-dir DIR] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="$2"; shift 2;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for cmd in docker df; do need "$cmd"; done
require_install
docker info >/dev/null 2>&1 || die "Docker daemon is unavailable"
compose config --quiet
compose ps
df -h "$FLOWCAST_HOME"
log "Configuration valid; secrets intentionally omitted."
