#!/usr/bin/env bash
set -euo pipefail
# Non-destructive Docker API validation. This script never creates, starts, or stops a container.
# shellcheck source=scripts/lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

require_install
load_env
if [[ "${FLOWCAST_DOCKER_CONTROL_ENABLED:-false}" != true ]]; then
  log "docker_control=DISABLED"
  exit 0
fi

id="$(compose ps -q control 2>/dev/null || true)"
[[ -n "$id" ]] || die "docker_control=FAIL cause=control container is missing"

project="$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id" 2>/dev/null || true)"
[[ -n "$project" ]] || die "docker_control=FAIL cause=control has no Compose project label"

if ! compose exec -T -e FLOWCAST_COMPOSE_PROJECT="$project" control python - <<'PY'
import json
import os
import socket
import sys
import urllib.parse

SOCKET = "/var/run/docker.sock"

def get(path):
    request = f"GET {path} HTTP/1.1\r\nHost: docker\r\nConnection: close\r\n\r\n".encode()
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(5)
    try:
        client.connect(SOCKET)
        client.sendall(request)
        chunks = []
        while True:
            chunk = client.recv(65536)
            if not chunk:
                break
            chunks.append(chunk)
    finally:
        client.close()
    response = b"".join(chunks)
    header, separator, body = response.partition(b"\r\n\r\n")
    if not separator or b" 200 " not in header.split(b"\r\n", 1)[0]:
        raise RuntimeError("Docker API returned a non-200 response")
    return body

try:
    if get("/_ping").strip() != b"OK":
        raise RuntimeError("Docker daemon ping did not return OK")
    project = os.environ["FLOWCAST_COMPOSE_PROJECT"]
    filters = {"label": [f"com.docker.compose.project={project}", "com.docker.compose.service=engine"]}
    path = "/containers/json?all=1&filters=" + urllib.parse.quote(json.dumps(filters, separators=(",", ":")))
    containers = json.loads(get(path))
    if len(containers) != 1:
        raise RuntimeError(f"expected one engine for Compose project {project}, found {len(containers)}")
    state = containers[0].get("State", "unknown")
    print(f"daemon=reachable project={project} engine_state={state}")
except PermissionError as exc:
    print(f"permission denied opening {SOCKET}: {exc}", file=sys.stderr)
    raise SystemExit(1)
except (OSError, ValueError, KeyError, RuntimeError) as exc:
    print(str(exc), file=sys.stderr)
    raise SystemExit(1)
PY
then
  die "docker_control=FAIL cause=daemon ping, socket permission, project, or engine resolution failed"
fi
log "docker_control=PASS"
