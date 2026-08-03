# Backup, update and rollback

[Repository home](../../README.md) · [Documentation index](../README.md) · [Previous guide](reverse-proxy-tls.md) · [Next guide](docker-control.md)

## Objective

Protect local state, apply a tagged update and recover deliberately.

## Prerequisites

A healthy installation, adequate backup capacity and the exact target release tag.

## Procedure

1. Create a backup with `sudo /opt/flowcast/scripts/community/backup.sh`; add `--include-media` only when capacity permits.
2. Protect the archive because it contains `.env`, and record its path.
3. Update with `sudo /opt/flowcast/scripts/community/update.sh --version VERSION`, replacing `VERSION` with a published tag documented by the release.
4. Run `sudo /opt/flowcast/scripts/community/doctor.sh`.
5. If restoration is required, use `sudo /opt/flowcast/scripts/community/restore.sh --backup FILE` with the selected compatible archive.

## Expected result

The requested version is healthy and existing credentials, volumes and explicit Docker Control choice remain preserved.

## Verification

Check `VERSION`, service health and `RESULT=PASS`; perform a controlled listener test.

## Troubleshooting

Read the target release notes. Preview state formats may not be downgrade compatible; never guess a version or archive path.

## Rollback

Follow the release-specific rollback instructions. Restore `.env.pre-update` and a compatible backup when required; validate again with `doctor.sh`.

## Related documentation

- [Quick start](../community/quick-start.md)
- [Runtime contract](../community/runtime-contract.md)
- [Security policy](../../SECURITY.md)
