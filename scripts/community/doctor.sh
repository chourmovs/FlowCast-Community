#!/usr/bin/env bash
set -uo pipefail
# Outputs only allow-listed diagnostics. It never prints .env, hashes named after secrets, or secret values.
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
FAILED=()
check_fail() { FAILED+=("$1"); log "$1=FAIL${2:+ cause=$2}"; }
check_pass() { log "$1=PASS${2:+ $2}"; }
timestamp() { date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S%z'; }
usage() { echo "Usage: doctor.sh [--install-dir DIR] [--help]"; }
while (($#)); do case "$1" in --install-dir) FLOWCAST_HOME="${2:?}"; shift 2;; --help|-h) usage; exit 0;; *) die "Unknown option: $1";; esac; done
for command in docker df curl sha256sum stat; do command -v "$command" >/dev/null 2>&1 || { echo "Missing $command" >&2; exit 1; }; done
require_install; load_env
log "doctor_started=$(timestamp) version=${FLOWCAST_VERSION:-unknown} architecture=$(uname -m)"
for file in compose.yml compose.docker-control.yml .env; do
  if [[ -f "$FLOWCAST_HOME/$file" ]]; then check_pass "file_$file"; else check_fail "file_$file"; fi
done
env_mode="$(stat -c '%a' "$FLOWCAST_HOME/.env" 2>/dev/null || true)"
if [[ "$env_mode" == 600 ]]; then check_pass env_permissions "mode=600"; else check_fail env_permissions "mode=${env_mode:-unknown}"; fi
disk="$(df -Pk "$FLOWCAST_HOME" | awk 'NR==2 {print $4}')"
if (( ${disk:-0} >= 1048576 )); then check_pass disk_space "available_kib=$disk"; else check_fail disk_space; fi
if ! docker info >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then check_fail docker_host; else check_pass docker_host; fi
if compose config --quiet >/dev/null 2>&1; then check_pass compose_config; else check_fail compose_config; fi
services="$(compose config --services 2>/dev/null || true)"
for service in storage-init icecast bliss audio-daemon engine control; do
  if ! printf '%s\n' "$services" | grep -Fxq "$service"; then check_fail "service_$service" "not_configured"; continue; fi
  id="$(compose ps -aq "$service" 2>/dev/null || true)"; [[ -n "$id" ]] || { check_fail "service_$service" "missing"; continue; }
  state="$(docker inspect -f '{{.State.Status}}' "$id" 2>/dev/null)"; health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$id" 2>/dev/null)"; restarts="$(docker inspect -f '{{.RestartCount}}' "$id" 2>/dev/null)"
  labels="$(docker inspect -f '{{index .Config.Labels "com.docker.compose.project"}}/{{index .Config.Labels "com.docker.compose.service"}}' "$id" 2>/dev/null)"
  log "service_$service=present state=$state health=$health restarts=$restarts labels=$labels"
  if [[ "$service" == storage-init ]]; then [[ "$state" == exited ]] || check_fail "health_$service"; else [[ "$state" == running && "$health" == healthy ]] || check_fail "health_$service"; fi
done
# Compare values in container configuration without ever writing either value.
engine_id="$(compose ps -q engine 2>/dev/null || true)"; icecast_id="$(compose ps -q icecast 2>/dev/null || true)"
engine_secret="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$engine_id" 2>/dev/null | sed -n 's/^ICECAST_PASSWORD=//p')"
icecast_secret="$(docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "$icecast_id" 2>/dev/null | sed -n 's/^ICECAST_SOURCE_PASSWORD=//p')"
if [[ -n "$engine_secret" && "$engine_secret" == "$icecast_secret" ]]; then check_pass source_credentials "MATCH"; else check_fail source_credentials "MISMATCH"; fi
unset engine_secret icecast_secret
config_control="$(compose exec -T control sha256sum /flowcast/config/config.yml 2>/dev/null | awk '{print $1}')"; config_engine="$(compose exec -T engine sha256sum /flowcast/config/config.yml 2>/dev/null | awk '{print $1}')"
if [[ -n "$config_control" && "$config_control" == "$config_engine" ]]; then check_pass shared_config; else check_fail shared_config; fi
mount="$(compose exec -T control sh -c "sed -n 's/^[[:space:]]*mount:[[:space:]]*//p' /flowcast/config/config.yml | head -n1" 2>/dev/null | tr -d '\r\"\047')"; [[ "$mount" == /* ]] || mount=/test.mp3
check_pass configured_mount "path=$mount"
if [[ "${FLOWCAST_DOCKER_CONTROL_ENABLED:-false}" == true ]]; then
  if compose exec -T control sh -c 'test -S /var/run/docker.sock && test -r /var/run/docker.sock && test -w /var/run/docker.sock' >/dev/null 2>&1; then check_pass docker_socket; else check_fail docker_socket; fi
  actual_gid="$(compose exec -T control stat -c '%g' /var/run/docker.sock 2>/dev/null || true)"
  if [[ -n "$actual_gid" && "$actual_gid" == "${FLOWCAST_DOCKER_GID:-}" ]]; then check_pass docker_socket_gid; else check_fail docker_socket_gid; fi
  if FLOWCAST_HOME="$FLOWCAST_HOME" "$(dirname "${BASH_SOURCE[0]}")/check-docker-control.sh" >/dev/null 2>&1; then check_pass docker_ping "engine_unique=true controls_available=true"; else check_fail docker_ping; fi
else log 'docker_control=DISABLED'; fi
if compose exec -T control curl -fsS --max-time 5 http://icecast:8000/status-json.xsl >/dev/null 2>&1; then check_pass internal_icecast; else check_fail internal_icecast; fi
base="http://127.0.0.1:${FLOWCAST_HTTP_PORT:-8080}"
for endpoint in /api/config/mountpoints /api/stations /api/panel/now; do
  body="$(curl -fsS --max-time 5 "$base$endpoint" 2>/dev/null || true)"
  if [[ -n "$body" ]]; then check_pass "api_${endpoint//\//_}"; else check_fail "api_${endpoint//\//_}"; fi
  [[ "$body" == *"$mount"* ]] || check_fail "api_mount_${endpoint//\//_}"
done
stream_check() { local name=$1 url=$2 tmp rc bytes; tmp="$(mktemp)"; curl -fsS --max-time 5 "$url" -o "$tmp" >/dev/null 2>&1; rc=$?; bytes="$(wc -c <"$tmp")"; rm -f "$tmp"; if { [[ $rc == 0 || $rc == 28 ]]; } && (( bytes >= ${FLOWCAST_STREAM_MIN_BYTES:-4096} )); then check_pass "$name" "http=200 bytes=$bytes"; else check_fail "$name" "curl=$rc bytes=$bytes"; fi; }
stream_check direct_stream "http://127.0.0.1:${FLOWCAST_STREAM_PORT:-8010}$mount"
stream_check proxy_stream "$base/listen$mount"
for service in engine control icecast; do recent="$(compose logs --since 10m "$service" 2>&1 | tail -n 500)"; if printf '%s' "$recent" | grep -Eqi '(password=|ICECAST_SOURCE_PASSWORD=|401.*(metadata|\.POKE)|Login failed.*Login failed)'; then check_fail "logs_$service" "credential_or_auth_pattern"; else check_pass "logs_$service"; fi; done
log "secret values and data contents were intentionally omitted"
if ((${#FAILED[@]})); then printf 'RESULT=FAIL\nFAILED_CHECKS=%s\n' "$(IFS=,; echo "${FAILED[*]}")"; exit 1; fi
printf 'RESULT=PASS\n'
