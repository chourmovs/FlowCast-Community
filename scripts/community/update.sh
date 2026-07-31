#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
VERSION=""
usage() { echo "Usage: update.sh --version VERSION [--install-dir DIR] [--dry-run] [--help]"; }
while (($#)); do case "$1" in --version) VERSION="$2"; shift 2;; --install-dir) FLOWCAST_HOME="$2"; shift 2;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ -n "$VERSION" ]] || die "--version is required"; need docker; require_install
run cp "$FLOWCAST_HOME/.env" "$FLOWCAST_HOME/.env.pre-update"
if [[ "$DRY_RUN" == false ]]; then sed -i "s/^FLOWCAST_VERSION=.*/FLOWCAST_VERSION=${VERSION#v}/" "$FLOWCAST_HOME/.env"; fi
run compose pull
run compose up -d
log "Updated to ${VERSION#v}; see docs/community/update-rollback.md for rollback."
