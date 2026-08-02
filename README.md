# FlowCast Community 0.1.0-rc.6

FlowCast Community is a self-hosted radio control and playout stack. This release candidate targets Linux/amd64 with Docker Engine, Docker Compose v2, 4 GB RAM, 10 GB free disk, and host ports **8080** (web/proxy) and **8010** (direct Icecast).

## One-line installation

```bash
curl -fsSL https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v0.1.0-rc.6/install.sh | sudo bash -s -- --version 0.1.0-rc.6
```

A fresh RC6 installation enables Docker Control automatically, detects the Unix socket from `DOCKER_HOST=unix://…` or `/var/run/docker.sock`, records its GID, generates independent credentials, pulls the images, and waits for health checks. If the socket is unavailable the installer stops with an explanation; it never silently reduces functionality. Use `--no-docker-control` to explicitly opt out. The legacy `--docker-control` option remains accepted.

> **Security:** mounting the Docker socket gives `control` effectively root-equivalent control of the host. Only trusted administrators should operate FlowCast. The actual mount lives solely in `compose.docker-control.yml`.

Open `http://localhost:8080` locally (or the LAN URL printed by the installer). Listen through the same-origin player/proxy at `/listen/test.mp3`, or directly at `http://HOST:8010/test.mp3`. `control` always reaches Icecast internally as `http://icecast:8000`; published port 8010 is host-facing only.

`FLOWCAST_PUBLIC_URL` is optional and empty by default, so pages and players use portable same-origin relative links and forwarded reverse-proxy headers. Set it only when an explicit public domain/reverse-proxy origin is required; the installer never persists localhost or a detected LAN address as application truth.

## Credentials and diagnostics

Secrets are generated into `/opt/flowcast/.env` with mode 600 and are never printed during installation or diagnostics. On a local interactive terminal only, explicitly reveal the source credential with:

```bash
sudo /opt/flowcast/scripts/community/credentials.sh show-source
```

Run portable diagnostics (GNU/Linux or Alpine/BusyBox tooling; no Python dependency in engine) with:

```bash
sudo /opt/flowcast/scripts/community/doctor.sh
```

The result ends with `RESULT=PASS` or a redacted `RESULT=FAIL` and `FAILED_CHECKS` list.

## Updating RC5

Back up first, then run `sudo /opt/flowcast/scripts/community/update.sh --version 0.1.0-rc.6`. Existing secrets, volumes, media, ports, and the explicit Docker Control choice are preserved. An RC5 installation where Docker Control was disabled stays disabled. After reviewing the root-equivalent warning, opt in explicitly with `--enable-docker-control`. See [update and rollback](docs/community/update-rollback.md).

## Documentation

- [Quick start](docs/community/quick-start.md)
- [Configuration](docs/community/configuration.md)
- [Update and rollback](docs/community/update-rollback.md)
- [Backup and restore](docs/community/backup-restore.md)
- [Troubleshooting](docs/community/troubleshooting.md)
- [Architecture](docs/community/architecture.md)
- [Security policy](SECURITY.md)
