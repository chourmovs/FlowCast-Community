# Backup and restore

Run `scripts/community/backup.sh --output /secure/path`. It briefly stops services and archives the state volume; `.env` and media are deliberately excluded and require separate encrypted operator backups. Test archives away from the live host.

Restore only a trusted archive matching the intended release: `scripts/community/restore.sh --backup FILE`. Restore replaces current state, so take a fresh backup first. Both commands support `--dry-run` and `--install-dir`.
