#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: build-release.sh VERSION}"
[[ "$VERSION" =~ ^0\.1\.0-rc\.[0-9]+$ ]] || { echo 'invalid release version' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; DIST="$ROOT/dist"; STAGE="$DIST/stage"
rm -rf "$STAGE"; mkdir -p "$STAGE"; cp "$DIST/images.lock" "$STAGE/images.lock"
for path in compose.yml compose.docker-control.yml .env.example README.md LICENSE install.sh scripts docs; do cp -a "$ROOT/$path" "$STAGE/"; done
printf '%s\n' "$VERSION" >"$STAGE/VERSION"
jq -n --arg version "$VERSION" --arg commit "$(git -C "$ROOT" rev-parse HEAD)" --arg tag "v$VERSION" \
  '{schema_version:1,version:$version,git_commit:$commit,git_tag:$tag,platforms:["linux/amd64"],archive:{filename:("flowcast-community-v"+$version+".tar.gz"),sha256:"pending"},images_lock:"images.lock"}' >"$STAGE/release-manifest.json"
ARCHIVE="$DIST/flowcast-community-v$VERSION.tar.gz"
tar --sort=name --mtime="@$(git -C "$ROOT" log -1 --format=%ct)" --owner=0 --group=0 --numeric-owner -czf "$ARCHIVE" -C "$STAGE" .
sha256sum "$ARCHIVE" | sed "s#  $DIST/#  #" >"$DIST/checksums.sha256"
digest="$(cut -d' ' -f1 "$DIST/checksums.sha256")"
jq --arg digest "$digest" '.archive.sha256=$digest' "$STAGE/release-manifest.json" >"$DIST/release-manifest.json"
