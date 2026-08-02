# Update and rollback: RC5 to RC6

Create a backup, then update in place:

```bash
sudo /opt/flowcast/scripts/community/backup.sh
sudo /opt/flowcast/scripts/community/update.sh --version 0.1.0-rc.6
```

The updater saves `.env.pre-update`, preserves credentials, ports, volumes, media, and the user's Docker Control choice, removes obsolete `ICECAST_MOUNT` environment overrides, refreshes the socket GID when control is enabled, recreates `control` and `engine`, and waits for health checks. The mountpoint remains owned solely by `/flowcast/config/config.yml`.

RC5 installations with `FLOWCAST_DOCKER_CONTROL_ENABLED=false` **remain disabled**: an update never silently grants root-equivalent Docker socket access. To opt in after reviewing that risk:

```bash
sudo /opt/flowcast/scripts/community/update.sh --version 0.1.0-rc.6 --enable-docker-control
```

The socket defaults to `/var/run/docker.sock`; `DOCKER_HOST=unix:///another/path` is honored. When enabled, `compose.docker-control.yml` must exist and the socket must be accessible.

Validate after updating:

```bash
sudo /opt/flowcast/scripts/community/doctor.sh
```

To roll back, copy `.env.pre-update` to `.env`, run the prior release's Compose configuration with `pull` and `up -d --wait`, and restore a compatible backup if persisted formats changed. Preview releases do not guarantee downgrade-compatible state.
