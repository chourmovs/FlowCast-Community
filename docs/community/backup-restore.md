# Backup and restore

Run `/opt/flowcast/scripts/community/backup.sh`. It stops the stack while copying `.env`, both Compose files, catalog, settings, engine history, and analysis. Media are deliberately excluded by default because they can make the archive very large; pass `--include-media` to include `flowcast-media`.

Restore with `/opt/flowcast/scripts/community/restore.sh --backup FILE`. The stack is stopped during replacement and restarted afterward. Protect every archive as a secret because it contains `.env`, validate capacity first, and test restoration before relying on it.
