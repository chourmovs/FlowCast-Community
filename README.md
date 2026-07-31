# FlowCast Community Preview

FlowCast is a self-hosted radio control plane and playout stack for technical broadcasters, self-hosters, and early adopters. **Community Preview is not yet production-qualified. Back up your data before every upgrade.**

The public repository contains the control-plane distribution, operator tooling, and documented runtime contracts. Audio engines are distributed as versioned OCI images; their proprietary Rust sources are not included.

## Features

- Browser-based station control and status monitoring
- Automated playout through containerized engine, analyzer, Bliss, and Icecast services
- Version-pinned Docker Compose deployment for amd64 and arm64 Linux
- Update, backup, restore, uninstall, and diagnostic tools
- Community operation without a licence; optional Pro capabilities degrade cleanly

## Quick start

Prerequisites: Linux, Docker Engine with Compose v2, 4 GB RAM, 10 GB free disk, and TCP port 8080.

Review the script before running it. The recommended version-pinned installation is:

```bash
curl -fsSL https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v0.1.0/install.sh | bash
```

To follow the development branch instead:

```bash
curl -fsSL https://raw.githubusercontent.com/chourmovs/FlowCast-Community/main/install.sh | bash
```

The installer verifies release checksums, creates three independent Icecast secrets, and stores configuration at `/opt/flowcast` by default. See the [quick start](docs/community/quick-start.md) for a review-first installation.

## Architecture

The Python control plane communicates over documented HTTP/JSON contracts with versioned Rust engine images. It does not import or compile private engine sources. See [architecture](docs/community/architecture.md) and the [runtime contract](docs/community/runtime-contract.md).

## Documentation

- [Configuration](docs/community/configuration.md)
- [Backup and restore](docs/community/backup-restore.md)
- [Update and rollback](docs/community/update-rollback.md)
- [Troubleshooting](docs/community/troubleshooting.md)
- [Supported platforms](docs/community/supported-platforms.md)
- [Community versus Pro](docs/community/community-vs-pro.md)
- [Known limitations](docs/community/known-limitations.md)

## Community and Pro

Community starts and broadcasts without a licence or a mandatory licence-server call. Pro UI affordances may be visible but remain disabled unless explicitly configured with valid credentials. No licence credential ships here. Details and transmitted metadata are documented in [Community versus Pro](docs/community/community-vs-pro.md).

## Screenshots

> **Placeholder:** verified Community Preview screenshots will be added after the public OCI images complete release qualification.

## Limitations and support

OCI images may not yet be publicly available for every architecture. Endurance qualification, unattended rollback, and production support SLAs are not complete. Support is best effort through GitHub Discussions and sanitized issues; never attach `.env`, credentials, station media, or database files.

Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md). Contributions follow [CONTRIBUTING.md](CONTRIBUTING.md). The repository is licensed under the [MIT License](LICENSE); distributed images may contain separately licensed components.
