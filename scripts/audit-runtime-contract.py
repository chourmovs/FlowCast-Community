#!/usr/bin/env python3
"""Audit the rendered FlowCast Community Compose runtime contract.

The current release version is read exclusively from:

    version.env -> FLOWCAST_VERSION
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
VERSION_ENV = ROOT / "version.env"
ENV_EXAMPLE = ROOT / ".env.example"
COMPOSE_FILE = ROOT / "compose.yml"
DOCKER_CONTROL_FILE = ROOT / "compose.docker-control.yml"

EXPECTED_SERVICES = {
    "storage-init",
    "control",
    "engine",
    "audio-daemon",
    "bliss",
    "icecast",
}

VERSION_PATTERN = re.compile(
    r"^[0-9]+\.[0-9]+\.[0-9]+"
    r"(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?"
    r"(?:\+[0-9A-Za-z][0-9A-Za-z.-]*)?$"
)


def read_env_file(path: Path) -> dict[str, str]:
    if not path.is_file():
        raise RuntimeError(f"Required environment file is missing: {path}")

    values: dict[str, str] = {}

    for line_number, raw_line in enumerate(
        path.read_text(encoding="utf-8").splitlines(),
        start=1,
    ):
        line = raw_line.strip()

        if not line or line.startswith("#"):
            continue

        if "=" not in line:
            raise RuntimeError(
                f"{path}:{line_number}: expected KEY=VALUE syntax"
            )

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()

        if not key:
            raise RuntimeError(
                f"{path}:{line_number}: empty variable name"
            )

        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in {"'", '"'}
        ):
            value = value[1:-1]

        values[key] = value

    return values


def current_version() -> str:
    values = read_env_file(VERSION_ENV)
    version = values.get("FLOWCAST_VERSION", "").strip()

    if not version:
        raise RuntimeError(
            "FLOWCAST_VERSION must be defined in version.env"
        )

    if not VERSION_PATTERN.fullmatch(version):
        raise RuntimeError(
            f"Invalid FLOWCAST_VERSION in version.env: {version!r}"
        )

    if version == "latest":
        raise RuntimeError(
            "FLOWCAST_VERSION cannot use the mutable 'latest' tag"
        )

    return version


def expected_images(version: str) -> dict[str, str]:
    return {
        "storage-init": (
            f"ghcr.io/chourmovs/flowcast-engine:{version}"
        ),
        "control": (
            f"ghcr.io/chourmovs/flowcast-control:{version}"
        ),
        "engine": (
            f"ghcr.io/chourmovs/flowcast-engine:{version}"
        ),
        "audio-daemon": (
            f"ghcr.io/chourmovs/flowcast-analyzer:{version}"
        ),
        "bliss": (
            f"ghcr.io/chourmovs/flowcast-bliss:{version}"
        ),
        "icecast": (
            f"ghcr.io/chourmovs/flowcast-icecast:{version}"
        ),
    }


def compose_environment() -> dict[str, str]:
    environment = os.environ.copy()
    environment.update(read_env_file(ENV_EXAMPLE))
    environment.update(read_env_file(VERSION_ENV))
    return environment


def render(*compose_files: str) -> dict[str, Any]:
    command = [
        "docker",
        "compose",
        "--env-file",
        str(ENV_EXAMPLE),
        "--env-file",
        str(VERSION_ENV),
    ]

    for compose_file in compose_files:
        command.extend(["-f", str(ROOT / compose_file)])

    command.extend(["config", "--format", "json"])

    environment = compose_environment()

    if "compose.docker-control.yml" in compose_files:
        environment["FLOWCAST_DOCKER_GID"] = "0"

    try:
        result = subprocess.run(
            command,
            check=True,
            text=True,
            capture_output=True,
            env=environment,
        )
    except FileNotFoundError as error:
        raise RuntimeError(
            "Docker or Docker Compose is unavailable"
        ) from error
    except subprocess.CalledProcessError as error:
        detail = (
            error.stderr.strip()
            or error.stdout.strip()
            or str(error)
        )
        raise RuntimeError(
            f"Compose render failed: {detail}"
        ) from error

    try:
        rendered = json.loads(result.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(
            "Docker Compose returned invalid JSON"
        ) from error

    if not isinstance(rendered, dict):
        raise RuntimeError(
            "Rendered Compose root must be an object"
        )

    return rendered


def flattened(value: Any) -> str:
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
    )


def find_dependency_cycle(
    services: dict[str, Any],
) -> bool:
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(name: str) -> bool:
        if name in visiting:
            return True

        if name in visited:
            return False

        visiting.add(name)

        depends_on = services.get(name, {}).get(
            "depends_on",
            {},
        )

        if isinstance(depends_on, dict):
            dependencies = depends_on.keys()
        elif isinstance(depends_on, list):
            dependencies = depends_on
        else:
            dependencies = []

        for dependency in dependencies:
            dependency_name = str(dependency)

            if (
                dependency_name in services
                and visit(dependency_name)
            ):
                return True

        visiting.remove(name)
        visited.add(name)
        return False

    return any(visit(name) for name in services)


def collect_volume_targets(
    services: dict[str, Any],
) -> set[str]:
    targets: set[str] = set()

    for service in services.values():
        if not isinstance(service, dict):
            continue

        for volume in service.get("volumes", []):
            if not isinstance(volume, dict):
                continue

            target = volume.get("target")

            if isinstance(target, str):
                targets.add(target)

    return targets


def audit(
    main: dict[str, Any],
    docker_control: dict[str, Any],
    source: str,
    images: dict[str, str],
) -> list[str]:
    errors: list[str] = []

    services = main.get("services", {})

    if not isinstance(services, dict):
        return ["rendered services must be an object"]

    actual_services = set(services)

    missing_services = EXPECTED_SERVICES - actual_services
    unexpected_services = actual_services - EXPECTED_SERVICES

    if missing_services:
        errors.append(
            f"required services are missing: "
            f"{sorted(missing_services)}"
        )

    if unexpected_services:
        errors.append(
            f"unexpected services are present: "
            f"{sorted(unexpected_services)}"
        )

    if re.search(r"(?m)^[ \t]*build[ \t]*:", source):
        errors.append(
            "build directives are forbidden in public Compose"
        )

    if re.search(
        r"(?m)^[ \t]*image[ \t]*:.*:latest"
        r"(?:[ \t]|$)",
        source,
    ):
        errors.append(
            "latest image tags are forbidden"
        )

    for service_name, expected_image in images.items():
        service = services.get(service_name, {})

        if not isinstance(service, dict):
            errors.append(
                f"{service_name} has an invalid definition"
            )
            continue

        actual_image = service.get("image")

        if actual_image != expected_image:
            errors.append(
                f"{service_name} image mismatch: "
                f"expected {expected_image!r}, "
                f"rendered {actual_image!r}"
            )

    analyzer = services.get("audio-daemon", {})
    engine = services.get("engine", {})
    control = services.get("control", {})
    bliss = services.get("bliss", {})

    if analyzer.get("command") != [
        "/usr/local/bin/flowcast-analyzer-entrypoint.sh"
    ]:
        errors.append(
            "audio-daemon entrypoint command is incorrect"
        )

    if analyzer.get("healthcheck", {}).get("test") != [
        "CMD",
        "/usr/local/bin/flowcast-analyzer",
        "--healthcheck",
    ]:
        errors.append(
            "audio-daemon must use the analyzer CLI healthcheck"
        )

    if engine.get("command") != [
        "/usr/local/bin/flowcast-engine-entrypoint.sh"
    ]:
        errors.append(
            "engine entrypoint command is incorrect"
        )

    if engine.get("healthcheck", {}).get("test") != [
        "CMD",
        "/usr/local/bin/flowcast-engine",
        "--healthcheck",
    ]:
        errors.append(
            "engine must use the strict engine CLI healthcheck"
        )

    if engine.get("healthcheck", {}).get(
        "start_period"
    ) not in {"120s", "2m0s"}:
        errors.append(
            "engine healthcheck must preserve a "
            "120-second bootstrap grace period"
        )

    if not any(
        isinstance(port, dict)
        and port.get("target") == 8088
        for port in control.get("ports", [])
    ):
        errors.append(
            "control must expose container port 8088"
        )

    if (
        "127.0.0.1:8090/health"
        not in flattened(
            bliss.get("healthcheck", {})
        )
    ):
        errors.append(
            "bliss healthcheck must use port 8090"
        )

    engine_environment = engine.get("environment", {})

    if (
        not isinstance(engine_environment, dict)
        or "ICECAST_PASSWORD"
        not in engine_environment
    ):
        errors.append(
            "engine is missing ICECAST_PASSWORD"
        )

    rendered_main = flattened(main)

    if "8091" in rendered_main or "8092" in rendered_main:
        errors.append(
            "retired internal ports 8091 and 8092 are forbidden"
        )

    targets = collect_volume_targets(services)

    retired_targets = {
        "/media",
        "/settings",
        "/history",
        "/analysis",
    }

    found_retired_targets = targets & retired_targets

    if found_retired_targets:
        errors.append(
            f"retired volume targets remain: "
            f"{sorted(found_retired_targets)}"
        )

    for required_target in (
        "/data/flowcast-media",
        "/data/analysis",
        "/flowcast",
    ):
        if required_target not in targets:
            errors.append(
                f"required volume target is missing: "
                f"{required_target}"
            )

    if "/var/run/docker.sock" in rendered_main:
        errors.append(
            "the main Compose file must not mount "
            "the Docker socket"
        )

    docker_control_services = docker_control.get(
        "services",
        {},
    )

    override_control = docker_control_services.get(
        "control",
        {},
    )

    if (
        override_control.get("environment", {}).get(
            "FLOWCAST_DOCKER_CONTROL_ENABLED"
        )
        != "true"
    ):
        errors.append(
            "Docker Control override must enable "
            "Docker Control"
        )

    if (
        "/var/run/docker.sock"
        not in flattened(
            override_control.get("volumes", [])
        )
    ):
        errors.append(
            "Docker Control override must mount "
            "the Docker socket"
        )

    docker_control_source = DOCKER_CONTROL_FILE.read_text(
        encoding="utf-8"
    )

    if "${FLOWCAST_DOCKER_GID" not in docker_control_source:
        errors.append(
            "Docker Control override must use the "
            "dynamically detected socket GID"
        )

    storage_dependency = control.get(
        "depends_on",
        {},
    ).get(
        "storage-init",
        {},
    )

    if (
        not isinstance(storage_dependency, dict)
        or storage_dependency.get("condition")
        != "service_completed_successfully"
    ):
        errors.append(
            "control must wait for successful storage-init"
        )

    if find_dependency_cycle(services):
        errors.append(
            "service dependency graph contains a cycle"
        )

    return errors


def main() -> int:
    try:
        version = current_version()
        images = expected_images(version)

        source = COMPOSE_FILE.read_text(
            encoding="utf-8"
        )

        main_compose = render("compose.yml")

        docker_control_compose = render(
            "compose.yml",
            "compose.docker-control.yml",
        )

        errors = audit(
            main_compose,
            docker_control_compose,
            source,
            images,
        )
    except (OSError, RuntimeError) as error:
        print(
            f"runtime contract: {error}",
            file=sys.stderr,
        )
        return 1

    if errors:
        for error in errors:
            print(
                f"runtime contract: {error}",
                file=sys.stderr,
            )

        return 1

    print(
        f"Runtime contract audit passed "
        f"for FlowCast {version}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
