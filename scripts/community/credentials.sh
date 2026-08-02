#!/usr/bin/env bash
set -euo pipefail
# Deliberately separate from doctor/CI: this command reveals a credential locally.
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
usage() { echo "Usage: credentials.sh show-source [--install-dir DIR]"; }
action="${1:-}"; [[ -n "$action" ]] && shift || true
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="${2:?}"; shift 2;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ "$action" == show-source ]] || { usage; exit 2; }
[[ -t 1 ]] || die "Refusing to reveal a credential to a non-interactive output (pipe, redirect, or CI log)."
require_install
mode="$(stat -c '%a' "$FLOWCAST_HOME/.env" 2>/dev/null || true)"
[[ "$mode" == 600 ]] || die "$FLOWCAST_HOME/.env must have mode 600 (found ${mode:-unknown})."
printf 'WARNING: this reveals the Icecast source password on this local terminal. Keep it secret.\n' >&2
sed -n 's/^ICECAST_SOURCE_PASSWORD=//p' "$FLOWCAST_HOME/.env"
