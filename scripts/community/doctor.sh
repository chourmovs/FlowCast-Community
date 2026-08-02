#!/usr/bin/env bash
set -euo pipefail
# This diagnostic intentionally allow-lists environment keys and never prints .env or database data.
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
usage() { echo "Usage: doctor.sh [--install-dir DIR] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="${2:?}"; shift 2;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for command in docker df curl; do need "$command"; done
require_install; load_env
failed=false
if docker info >/dev/null 2>&1; then log "host_docker_daemon=accessible"; else die "host_docker_daemon=unavailable"; fi
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is unavailable"
compose config --quiet
for file in compose.yml compose.docker-control.yml .env; do [[ -f "$FLOWCAST_HOME/$file" ]] || die "Missing required installation file: $file"; done
df -Pk "$FLOWCAST_HOME" | awk 'NR==2 && $4 < 1048576 {exit 1}' || die "Less than 1 GiB free disk remains"

if [[ "${FLOWCAST_DOCKER_CONTROL_ENABLED:-false}" == true ]]; then
  log "docker_control=enabled"
  if compose exec -T control sh -c 'test -S /var/run/docker.sock' >/dev/null 2>&1; then log "control_socket=mounted_unix"; else log "control_socket=absent_or_not_unix"; failed=true; fi
  if compose exec -T control sh -c 'test -r /var/run/docker.sock && test -w /var/run/docker.sock' >/dev/null 2>&1; then log "control_socket_permissions=read_write"; else log "control_socket_permissions=denied"; failed=true; fi
  if ! FLOWCAST_HOME="$FLOWCAST_HOME" "$(dirname "${BASH_SOURCE[0]}")/check-docker-control.sh"; then failed=true; fi
else
  log "docker_control=DISABLED"
  log "control_socket=not_mounted_by_standard_compose"
fi

engine_id=""
for service in storage-init icecast bliss audio-daemon engine control; do
  id="$(compose ps -aq "$service" 2>/dev/null || true)"
  if [[ -z "$id" ]]; then log "$service=missing"; failed=true; continue; fi
  status="$(docker inspect -f '{{.State.Status}}' "$id")"
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$id")"
  restarts="$(docker inspect -f '{{.RestartCount}}' "$id")"
  log "$service=present status=$status health=$health restarts=$restarts"
  [[ "$service" == storage-init && "$status" == exited ]] || [[ "$service" != storage-init && "$status" == running && "$health" == healthy ]] || failed=true
  [[ "$service" == engine ]] && engine_id="$id"
done

if curl -fsS --max-time 5 "http://127.0.0.1:${FLOWCAST_HTTP_PORT:-8080}/api/health" >/dev/null; then log "control_api=accessible"; else log "control_api=unavailable"; failed=true; fi
status_file="$(mktemp)"; stream_file="$(mktemp)"; trap 'rm -f "$status_file" "$stream_file"' EXIT
if curl -fsS --max-time 5 "http://127.0.0.1:${FLOWCAST_STREAM_PORT:-8010}/status-json.xsl" -o "$status_file"; then
  log "icecast_status=accessible"
  mount="$(python3 - "$status_file" <<'PY' 2>/dev/null || true
import json,sys
s=json.load(open(sys.argv[1], encoding='utf-8')).get('icestats',{}).get('source',[])
if isinstance(s,dict): s=[s]
if s:
 print(s[0].get('mount') or '/' + s[0].get('listenurl','').rsplit('/',1)[-1])
PY
)"
  if [[ -n "$mount" ]]; then
    log "icecast_mount=visible path=$mount"
    set +e; curl -fsS --max-time 3 "http://127.0.0.1:${FLOWCAST_STREAM_PORT:-8010}$mount" -o "$stream_file"; rc=$?; set -e
    if [[ "$rc" == 0 || "$rc" == 28 ]] && (( $(wc -c <"$stream_file") > 0 )); then log "stream=accessible"; else log "stream=unavailable"; failed=true; fi
  else log "icecast_mount=missing"; failed=true; fi
else log "icecast_status=unavailable"; failed=true; fi

if [[ -n "$engine_id" ]]; then
  if docker exec "$engine_id" sh -c 'test -s /tmp/flowcast_engine_health.json && test $(( $(date +%s) - $(stat -c %Y /tmp/flowcast_engine_health.json) )) -le 120' >/dev/null 2>&1; then log "engine_health_file=fresh"; else log "engine_health_file=missing_or_stale"; failed=true; fi
fi
if compose exec -T control python - <<'PY' >/dev/null 2>&1
import os,time
files=[os.path.join(p,n) for p,_,ns in os.walk('/runtime-state') for n in ns]
raise SystemExit(0 if files and time.time()-max(map(os.path.getmtime,files)) <= 120 else 1)
PY
then log "runtime_state=fresh"; else log "runtime_state=missing_or_stale"; failed=true; fi
if compose exec -T control sh -c 'find /data/engine_history -type f \( -name "*.db" -o -name "*.sqlite*" \) -size +0c -print -quit | grep -q .' >/dev/null 2>&1; then log "history_db=present_nonempty"; else log "history_db=missing_or_empty"; failed=true; fi

[[ "$failed" == false ]] || die "One or more diagnostics failed"
log "Diagnostics passed; secret values and data contents were intentionally omitted."
