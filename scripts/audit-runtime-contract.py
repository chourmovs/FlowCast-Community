#!/usr/bin/env python3
"""Audit the rendered public Compose runtime contract."""

import json
from pathlib import Path
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SERVICES = {"storage-init", "control", "engine", "audio-daemon", "bliss", "icecast"}
IMAGES = {
    "storage-init": "ghcr.io/chourmovs/flowcast-engine:0.1.0-rc.2",
    "control": "ghcr.io/chourmovs/flowcast-control:0.1.0-rc.2",
    "engine": "ghcr.io/chourmovs/flowcast-engine:0.1.0-rc.2",
    "audio-daemon": "ghcr.io/chourmovs/flowcast-analyzer:0.1.0-rc.2",
    "bliss": "ghcr.io/chourmovs/flowcast-bliss:0.1.0-rc.2",
    "icecast": "ghcr.io/chourmovs/flowcast-icecast:0.1.0-rc.2",
}


def render(*files):
    command = ["docker", "compose", "--env-file", str(ROOT / ".env.example")]
    for path in files:
        command += ["-f", str(ROOT / path)]
    command += ["config", "--format", "json"]
    return json.loads(subprocess.run(command, check=True, text=True, capture_output=True).stdout)


def flattened(value):
    return json.dumps(value, sort_keys=True)


def find_cycle(services):
    visiting, visited = set(), set()

    def visit(name):
        if name in visiting:
            return True
        if name in visited:
            return False
        visiting.add(name)
        for dependency in services[name].get("depends_on", {}):
            if dependency in services and visit(dependency):
                return True
        visiting.remove(name)
        visited.add(name)
        return False

    return any(visit(name) for name in services)


def audit(main, docker_control, source):
    errors = []
    services = main.get("services", {})
    if set(services) != SERVICES:
        errors.append(f"services must be exactly {sorted(SERVICES)}")
    if "build:" in source or ":latest" in source:
        errors.append("build directives and latest tags are forbidden")
    for name, image in IMAGES.items():
        if services.get(name, {}).get("image") != image:
            errors.append(f"{name} must use {image}")

    analyzer = services.get("audio-daemon", {})
    engine = services.get("engine", {})
    control = services.get("control", {})
    bliss = services.get("bliss", {})
    if analyzer.get("command") != ["/usr/local/bin/flowcast-analyzer-entrypoint.sh"]:
        errors.append("audio-daemon entrypoint command is incorrect")
    if analyzer.get("healthcheck", {}).get("test") != ["CMD", "/usr/local/bin/flowcast-analyzer", "--healthcheck"]:
        errors.append("audio-daemon must use the analyzer CLI healthcheck")
    if engine.get("command") != ["/usr/local/bin/flowcast-engine-entrypoint.sh"]:
        errors.append("engine entrypoint command is incorrect")
    if "flowcast_engine_health.json" not in flattened(engine.get("healthcheck", {})):
        errors.append("engine must use its health status file")
    if not any(port.get("target") == 8088 for port in control.get("ports", [])):
        errors.append("control must expose container port 8088")
    if "127.0.0.1:8090/health" not in flattened(bliss.get("healthcheck", {})):
        errors.append("bliss healthcheck must use port 8090")
    if "ICECAST_PASSWORD" not in engine.get("environment", {}):
        errors.append("engine is missing ICECAST_PASSWORD")

    rendered = flattened(main)
    if "8091" in rendered or "8092" in rendered:
        errors.append("retired internal ports 8091/8092 are forbidden")
    targets = {
        volume.get("target")
        for service in services.values()
        for volume in service.get("volumes", [])
    }
    retired = {"/media", "/settings", "/history", "/analysis"}
    if targets & retired:
        errors.append(f"retired volume targets remain: {sorted(targets & retired)}")
    for target in ("/data/flowcast-media", "/data/analysis", "/flowcast"):
        if target not in targets:
            errors.append(f"required volume target is missing: {target}")
    if "/var/run/docker.sock" in rendered:
        errors.append("the main Compose file must not mount the Docker socket")

    override_control = docker_control.get("services", {}).get("control", {})
    if override_control.get("environment", {}).get("FLOWCAST_DOCKER_CONTROL_ENABLED") != "true":
        errors.append("Docker control override must enable Docker control")
    if "/var/run/docker.sock" not in flattened(override_control.get("volumes", [])):
        errors.append("Docker control override must mount the Docker socket")
    if find_cycle(services):
        errors.append("service dependency graph contains a cycle")
    return errors


def main():
    source = (ROOT / "compose.yml").read_text()
    errors = audit(render("compose.yml"), render("compose.yml", "compose.docker-control.yml"), source)
    if errors:
        for error in errors:
            print(f"runtime contract: {error}", file=sys.stderr)
        return 1
    print("Runtime contract audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
