# First broadcast

[Repository home](../../README.md) · [Documentation index](../README.md) · [Next guide](import-music.md)

## Objective

Put a qualified Community installation on air and verify its stream.

## Prerequisites

A supported Linux amd64 host; completed tagged installation; operator-owned or freely licensed audio.

## Procedure

1. Open `http://localhost:8080` and sign in with the locally generated credentials.
2. Import a permitted media file using the authenticated media interface.
3. Create or select a playlist and add the media.
4. Configure programming for the playlist in the scheduling interface.
5. Start playout. UI service controls require Docker Control; otherwise use the installation’s normal service lifecycle.
6. Listen through `/listen/test.mp3` on the control origin or through `http://HOST:8010/test.mp3`.
7. Run `sudo /opt/flowcast/scripts/community/doctor.sh`.

## Expected result

The selected item plays and the listener endpoint returns audio.

## Verification

Confirm that `doctor.sh` ends in `RESULT=PASS`.

## Troubleshooting

If media or scheduling is unclear, follow the three focused broadcasting guides. For runtime failures, use the stream troubleshooting guide.

## Rollback

Stop playout from the same authenticated control used to start it. Uninstall only when intended with `sudo /opt/flowcast/scripts/community/uninstall.sh`; do not add `--purge-data` unless permanent deletion is intended.

## Related documentation

- [Quick start](../community/quick-start.md)
- [Runtime contract](../community/runtime-contract.md)
- [Security policy](../../SECURITY.md)
