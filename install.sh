#!/usr/bin/env bash
set -euo pipefail
VERSION="${FLOWCAST_VERSION:-0.1.0}"; INSTALL_DIR="${FLOWCAST_HOME:-/opt/flowcast}"; START=true; DRY_RUN=false; DOCKER_CONTROL=false
REPOSITORY="${FLOWCAST_RELEASE_REPOSITORY:-chourmovs/FlowCast-Community}"
usage() { echo "Usage: install.sh [--version VERSION] [--install-dir DIR] [--no-start] [--docker-control] [--non-interactive] [--dry-run] [--help]"; }
die() { printf '[flowcast] ERROR: %s\n' "$*" >&2; exit 1; }; log() { printf '[flowcast] %s\n' "$*"; }; need() { command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"; }
while (($#)); do case "$1" in --version) VERSION="$2"; shift 2;; --install-dir) INSTALL_DIR="$2"; shift 2;; --no-start) START=false; shift;; --docker-control) DOCKER_CONTROL=true; shift;; --non-interactive) shift;; --dry-run) DRY_RUN=true; shift;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
[[ "$(uname -s)" == Linux ]] || die "Only Linux is supported"
case "$(uname -m)" in x86_64|amd64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; *) die "Unsupported architecture: $(uname -m)";; esac
for cmd in curl sha256sum openssl docker df tar; do need "$cmd"; done
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required"
docker info >/dev/null 2>&1 || die "Cannot access Docker daemon; configure permissions (automatic sudo is not used)"
AVAILABLE="$(df -Pk / | awk 'NR==2 {print $4}')"; (( AVAILABLE >= 10485760 )) || die "At least 10 GiB free disk is required"
if command -v ss >/dev/null && ss -ltnH | awk '{print $4}' | grep -Eq '(^|:)8080$'; then die "TCP port 8080 is in use"; fi
TAG="v${VERSION#v}"; BASE="https://github.com/$REPOSITORY/releases/download/$TAG"; ARCHIVE="flowcast-community-$TAG-$ARCH.tar.gz"
log "Preparing $TAG for $ARCH in $INSTALL_DIR"
if [[ "$DRY_RUN" == true ]]; then log "Would download and verify $BASE/$ARCHIVE, then start Compose"; exit 0; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
curl -fL --proto '=https' --tlsv1.2 -o "$TMP/$ARCHIVE" "$BASE/$ARCHIVE"
curl -fL --proto '=https' --tlsv1.2 -o "$TMP/checksums.sha256" "$BASE/checksums.sha256"
(cd "$TMP" && grep "  $ARCHIVE$" checksums.sha256 | sha256sum -c -) || die "Checksum verification failed"
mkdir -p "$INSTALL_DIR" || die "Cannot create $INSTALL_DIR; create it with suitable ownership"
tar -xzf "$TMP/$ARCHIVE" -C "$INSTALL_DIR"
secret() { openssl rand -hex 24; }; umask 077
cat >"$INSTALL_DIR/.env" <<EOF
FLOWCAST_VERSION=${VERSION#v}
FLOWCAST_HTTP_PORT=8080
FLOWCAST_AUTH_ENABLED=true
FLOWCAST_DOCKER_CONTROL_ENABLED=$DOCKER_CONTROL
FLOWCAST_PUBLIC_URL=http://localhost:8080
ICECAST_SOURCE_PASSWORD=$(secret)
ICECAST_RELAY_PASSWORD=$(secret)
ICECAST_ADMIN_PASSWORD=$(secret)
EOF
chmod 600 "$INSTALL_DIR/.env"
if [[ "$DOCKER_CONTROL" == true ]]; then log "WARNING: Docker control requires the reviewed operator override and grants host-level control."; fi
if [[ "$START" == true ]]; then
  dc=(docker compose --project-directory "$INSTALL_DIR" --env-file "$INSTALL_DIR/.env" -f "$INSTALL_DIR/compose.yml")
  "${dc[@]}" pull; "${dc[@]}" up -d
  deadline=$((SECONDS + 300))
  until [[ "$("${dc[@]}" ps --format json 2>/dev/null | grep -c '"Health":"healthy"' || true)" -ge 5 ]]; do (( SECONDS < deadline )) || die "Health timeout; run scripts/community/doctor.sh"; sleep 5; done
fi
log "URL: http://localhost:8080"
log "Diagnostics: FLOWCAST_HOME=$INSTALL_DIR $INSTALL_DIR/scripts/community/doctor.sh"
log "Backup: FLOWCAST_HOME=$INSTALL_DIR $INSTALL_DIR/scripts/community/backup.sh"
