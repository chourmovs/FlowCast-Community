# Import music

[Repository home](../../README.md) · [Documentation index](../README.md) · [Previous guide](first-broadcast.md) · [Next guide](create-playlist.md)

## Objective

Add redistributable audio to the Community media library.

## Prerequisites

A running installation, authenticated control access, and an audio file the operator has rights to store and broadcast.

## Procedure

1. Open the media library in the authenticated interface.
2. Choose its import/upload action and select the permitted file.
3. Wait for ingestion and analysis to finish; do not navigate away if the interface reports active transfer.
4. Review the displayed metadata and correct it through available interface fields.

## Expected result

The media entry appears in the library and becomes available for playlist selection.

## Verification

Confirm the item is playable in the interface and has no failed analysis state.

## Troubleshooting

Check free space and run `sudo /opt/flowcast/scripts/community/doctor.sh`. Do not paste the media or private metadata into an issue.

## Rollback

Delete the imported item through the authenticated library only if it is not referenced by required programming.

## Related documentation

- [Quick start](../community/quick-start.md)
- [Runtime contract](../community/runtime-contract.md)
- [Security policy](../../SECURITY.md)
