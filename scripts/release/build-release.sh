#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: build-release.sh VERSION}"
[[ "$VERSION" =~ ^0\.1\.0-rc\.[0-9]+$ ]] || { echo 'invalid release version' >&2; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; DIST="$ROOT/dist"; STAGE="$DIST/stage"
rm -rf "$STAGE"; mkdir -p "$STAGE"; cp "$DIST/images.lock" "$STAGE/images.lock"
for path in compose.yml compose.docker-control.yml .env.example versions.env README.md LICENSE install.sh scripts docs; do cp -a "$ROOT/$path" "$STAGE/"; done
find "$STAGE" -type d \( -name __pycache__ -o -name .pytest_cache \) -prune -exec rm -rf {} +
printf '%s\n' "$VERSION" >"$STAGE/VERSION"
sed -i "s/^FLOWCAST_VERSION=.*/FLOWCAST_VERSION=$VERSION/" "$STAGE/.env.example" "$STAGE/versions.env"
jq -n --arg version "$VERSION" --arg commit "$(git -C "$ROOT" rev-parse HEAD)" --arg tag "v$VERSION" \
  '{schema_version:1,version:$version,git_commit:$commit,git_tag:$tag,platforms:["linux/amd64"],archive:{filename:("flowcast-community-v"+$version+".tar.gz"),sha256:"pending"},images_lock:"images.lock"}' >"$STAGE/release-manifest.json"
ARCHIVE="$DIST/flowcast-community-v$VERSION.tar.gz"
tar --sort=name --mtime="@$(git -C "$ROOT" log -1 --format=%ct)" --owner=0 --group=0 --numeric-owner -czf "$ARCHIVE" -C "$STAGE" .

# Never ship a stale runtime assembled from anything other than this checkout.
EXTRACTED="$(mktemp -d)"
trap 'rm -rf "$EXTRACTED"' EXIT
tar -xzf "$ARCHIVE" -C "$EXTRACTED"
for path in compose.yml compose.docker-control.yml install.sh .env.example scripts/community/doctor.sh; do
  if [[ "$path" == .env.example ]]; then continue; fi
  cmp "$ROOT/$path" "$EXTRACTED/$path"
done
grep -Fq '/usr/local/bin/flowcast-analyzer' "$EXTRACTED/compose.yml"
grep -Fq -- '--healthcheck' "$EXTRACTED/compose.yml"
! grep -Fq 'http://localhost:8091/health' "$EXTRACTED/compose.yml"
! grep -Fq 'http://localhost:8092/health' "$EXTRACTED/compose.yml"
python3 - "$EXTRACTED" "$VERSION" <<'PY'
from pathlib import Path
import re, sys
root, expected = Path(sys.argv[1]), sys.argv[2]
effective = [root / "VERSION", root / ".env.example", root / "versions.env"]
found = {value for path in effective for value in re.findall(r"0\.1\.0-(?:dev|rc\.\d+)", path.read_text())}
if found != {expected}:
    raise SystemExit(f"release archive has contradictory effective versions: {sorted(found)}; expected {expected}")
PY

sha256sum "$ARCHIVE" | sed "s#  $DIST/#  #" >"$DIST/checksums.sha256"
digest="$(cut -d' ' -f1 "$DIST/checksums.sha256")"
jq --arg digest "$digest" '.archive.sha256=$digest' "$STAGE/release-manifest.json" >"$DIST/release-manifest.json"
