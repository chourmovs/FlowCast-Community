# FlowCast Community — Beta preview

FlowCast Community is a self-hosted radio control and playout stack for evaluation by technical broadcasters and self-hosters. **This beta preview is not production-grade.** Back up before every change.

## Requirements

- **linux/amd64 only** (ARM64 is not published for this beta)
- Docker Engine and Docker Compose v2
- 4 GB RAM and 10 GB free disk minimum
- host ports 8080 (interface) and 8010 (Icecast)

## Quick start

Install the versioned public release into `/opt/flowcast`:

```bash
curl -fsSL \
  https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v0.1.0-rc.2/install.sh \
  | sudo bash -s -- --version 0.1.0-rc.x
```

The installer downloads the release archive and metadata, verifies its SHA-256 checksum and version, generates three independent secrets, pulls the public GHCR images, and waits up to five minutes for every service. It never installs Docker and never invokes `sudo` itself.

### Review first

```bash
curl -fsSLO \
  https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v0.1.0-rc.x/install.sh

less install.sh

sudo bash install.sh --version 0.1.0-rc.x
```

After startup, open `http://localhost:8080`; Icecast is at `http://localhost:8010`. See the [quick start](docs/community/quick-start.md) and [configuration guide](docs/community/configuration.md).

## Operations and documentation

- [Backup and restore](docs/community/backup-restore.md)
- [Update and rollback](docs/community/update-rollback.md)
- [Troubleshooting](docs/community/troubleshooting.md)
- [Supported platforms](docs/community/supported-platforms.md)
- [Architecture](docs/community/architecture.md)
- [Community versus Pro](docs/community/community-vs-pro.md)

## Maintainer release process

Community beta releases follow the
[release checklist](RELEASE_CHECKLIST.md) and the
[detailed operator runbook](docs/release/community-beta-release.md).

The optional `--docker-control` mode mounts the Docker socket and therefore grants effectively root-level host control. It is off by default. Support is best effort; never share `.env`, credentials, media, or databases in an issue.
