#!/usr/bin/env python3
"""Audit the rendered public Compose runtime contract.

The FlowCast release version has a single source of truth:

    .env.example -> FLOWCAST_VERSION

The Compose files, runtime-contract audit and release tooling must consume that
value instead of maintaining independent hard-coded versions.
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
    """Read a simple KEY=VALUE environment file.

    This parser intentionally supports the syntax used by `.env.example` and
    does not attempt to implement shell expansion.
    """

    if not path.is_file():
        raise RuntimeError(f"Environment file is missing: {path}")

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
                f"{path}:{line_number}: empty environment variable name"
            )

        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in {"'", '"'}
        ):
            value = value[1:-1]

        values[key] = value

    return values


def release_version(environment: dict[str, str]) -> str:
    """Return and validate the unique FlowCast release version."""

    version = environment.get("FLOWCAST_VERSION", "").strip()

    if not version:
        raise RuntimeError(
            "FLOWCAST_VERSION must be defined in .env.example"
        )

    if not VERSION_PATTERN.fullmatch(version):
        raise RuntimeError(
            "FLOWCAST_VERSION has an invalid version format: "
            f"{version!r}"
        )

    if version == "latest":
        raise RuntimeError(
            "FLOWCAST_VERSION must be immutable and cannot be 'latest'"
        )

    return version


def expected_images(version: str) -> dict[str, str]:
    """Build the expected immutable image references."""

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


def render(
    environment_values: dict[str, str],
    *compose_files: str,
) -> dict[str, Any]:
    """Render one or more Compose files as JSON."""

    command = [
        "docker",
        "compose",
        "--env-file",
        str(ENV_EXAMPLE),
    ]

    for compose_file in compose_files:
        command.extend(
            [
                "-f",
                str(ROOT / compose_file),
            ]
        )

    command.extend(
        [
            "config",
            "--format",
            "json",
        ]
    )

    environment = os.environ.copy()
    environment.update(environment_values)

    # Docker Control requires a socket GID in real deployments. A harmless
    # render-only value is supplied in CI without weakening the runtime check.
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
            "Docker or Docker Compose is not available"
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
            "Docker Compose JSON root must be an object"
        )

    return rendered


def flattened(value: Any) -> str:
    """Return stable JSON text for broad contract searches."""

    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
    )


def find_dependency_cycle(
    services: dict[str, Any],
) -> bool:
    """Return True when the Compose dependency graph contains a cycle."""

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(name: str) -> bool:
        if name in visiting:
            return True

        if name in visited:
            return False

        visiting.add(name)

        dependencies = services.get(name, {}).get(
            "depends_on",
            {},
        )

        if isinstance(dependencies, list):
            dependency_names = dependencies
        elif isinstance(dependencies, dict):
            dependency_names = dependencies.keys()
        else:
            dependency_names = []

        for dependency in dependency_names:
            if (
                dependency in services
                and visit(str(dependency))
            ):
                return True

        visiting.remove(name)
        visited.add(name)
        return False

    return any(
        visit(service_name)
        for service_name in services
    )


def volume_targets(
    services: dict[str, Any],
) -> set[str]:
    """Collect all container-side volume targets."""

    targets: set[str] = set()

    for service in services.values():
        if not isinstance(service, dict):
            continue

        for volume in service.get("volumes", []):
            if isinstance(volume, dict):
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
    """Return all runtime-contract violations."""

    errors: list[str] = []

    services = main.get("services", {})

    if not isinstance(services, dict):
        return ["rendered Compose services must be an object"]

    actual_services = set(services)

    if actual_services != EXPECTED_SERVICES:
        missing = sorted(
            EXPECTED_SERVICES - actual_services
        )
        unexpected = sorted(
            actual_services - EXPECTED_SERVICES
        )

        if missing:
            errors.append(
                f"required services are missing: {missing}"
            )

        if unexpected:
            errors.append(
                f"unexpected services are present: {unexpected}"
            )

    if re.search(
        r"(?m)^[ \t]*build[ \t]*:",
        source,
    ):
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
                f"{service_name} has an invalid service definition"
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

    expected_analyzer_healthcheck = [
        "CMD",
        "/usr/local/bin/flowcast-analyzer",
        "--healthcheck",
    ]

    if (
        analyzer.get("healthcheck", {}).get("test")
        != expected_analyzer_healthcheck
    ):
        errors.append(
            "audio-daemon must use the analyzer CLI healthcheck"
        )

    if engine.get("command") != [
        "/usr/local/bin/flowcast-engine-entrypoint.sh"
    ]:
        errors.append(
            "engine entrypoint command is incorrect"
        )

    expected_engine_healthcheck = [
        "CMD",
        "/usr/local/bin/flowcast-engine",
        "--healthcheck",
    ]

    if (
        engine.get("healthcheck", {}).get("test")
        != expected_engine_healthcheck
    ):
        errors.append(
            "engine must use the strict engine CLI healthcheck"
        )

    engine_start_period = (
        engine.get("healthcheck", {})
        .get("start_period")
    )

    if engine_start_period not in {
        "2m0s",
        "120s",
    }:
        errors.append(
            "engine healthcheck must preserve a "
            "120-second bootstrap grace period"
        )

    control_ports = control.get("ports", [])

    if not any(
        isinstance(port, dict)
        and port.get("target") == 8088
        for port in control_ports
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

    engine_environment = engine.get(
        "environment",
        {},
    )

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

    targets = volume_targets(services)

    retired_targets = {
        "/media",
        "/settings",
        "/history",
        "/analysis",
    }

    remaining_retired_targets = (
        targets & retired_targets
    )

    if remaining_retired_targets:
        errors.append(
            "retired volume targets remain: "
            f"{sorted(remaining_retired_targets)}"
        )

    required_targets = {
        "/data/flowcast-media",
        "/data/analysis",
        "/flowcast",
    }

    for target in sorted(required_targets):
        if target not in targets:
            errors.append(
                f"required volume target is missing: {target}"
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

    override_environment = override_control.get(
        "environment",
        {},
    )

    if (
        override_environment.get(
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

    docker_control_source = (
        DOCKER_CONTROL_FILE.read_text(
            encoding="utf-8"
        )
    )

    if "${FLOWCAST_DOCKER_GID" not in docker_control_source:
        errors.append(
            "Docker Control override must use the "
            "dynamically detected socket GID"
        )

    control_dependencies = control.get(
        "depends_on",
        {},
    )

    storage_dependency = control_dependencies.get(
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
        environment_values = read_env_file(
            ENV_EXAMPLE
        )
        version = release_version(
            environment_values
        )
        images = expected_images(version)

        source = COMPOSE_FILE.read_text(
            encoding="utf-8"
        )

        main_compose = render(
            environment_values,
            "compose.yml",
        )

        docker_control_compose = render(
            environment_values,
            "compose.yml",
            "compose.docker-control.yml",
        )

        errors = audit(
            main_compose,
            docker_control_compose,
            source,
            images,
        )
    except (
        OSError,
        RuntimeError,
    ) as error:
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
        "Runtime contract audit passed "
        f"for FlowCast {version}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
