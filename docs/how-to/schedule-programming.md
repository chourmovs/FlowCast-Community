# Schedule programming

[Repository home](../../README.md) · [Documentation index](../README.md) · [Previous guide](create-playlist.md) · [Next guide](reverse-proxy-tls.md)

## Objective

Associate a playlist with an intended programming window.

## Prerequisites

A running installation and a verified playlist.

## Procedure

1. Open Programming/Scheduling in the authenticated interface.
2. Create or edit the intended schedule entry.
3. Select the playlist and configure only fields exposed by the current interface.
4. Save and inspect Upcoming to confirm the interpreted order/time.
5. Observe the transition at a safe test time before relying on it.

## Expected result

Upcoming reflects the entry and the engine selects it at the configured time.

## Verification

Check Now Playing/Upcoming and run `sudo /opt/flowcast/scripts/community/doctor.sh` after the transition.

## Troubleshooting

Check host time/time zone and conflicting entries. Use the stream troubleshooting guide if the schedule advances without audio.

## Rollback

Disable or remove the schedule entry in the same interface and verify Upcoming again.

## Related documentation

- [Quick start](../community/quick-start.md)
- [Runtime contract](../community/runtime-contract.md)
- [Security policy](../../SECURITY.md)
