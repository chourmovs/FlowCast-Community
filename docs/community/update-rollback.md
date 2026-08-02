# Update and rollback

Create a backup, review the prerelease notes, then run:

```bash
sudo /opt/flowcast/scripts/community/update.sh --version 0.1.0-rc.x
```

The script saves `.env.pre-update`, changes only `FLOWCAST_VERSION`, and runs Compose `pull` and `up -d`; it preserves ports, mode selection, and secrets. Operator scripts automatically add `compose.docker-control.yml` when enabled.

To roll back, copy `.env.pre-update` back to `.env`, run Compose `pull` and `up -d`, and restore a compatible backup if the release changed persisted data. Preview releases do not guarantee downgrade-compatible state.

`backup.sh` includes configuration, catalog, settings, engine history, and analysis. Media are excluded by default to avoid unexpectedly large archives; pass `--include-media` when required. Restore with `restore.sh --backup FILE`. Diagnose with `doctor.sh`; uninstall with `uninstall.sh` (data retained) or the destructive `--purge-data` option.
