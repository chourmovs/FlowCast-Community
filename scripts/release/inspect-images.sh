#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:?usage: inspect-images.sh VERSION}"
command -v jq >/dev/null || { echo 'jq is required' >&2; exit 1; }
services=(control engine analyzer bliss icecast)
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
for service in "${services[@]}"; do
  reference="ghcr.io/chourmovs/flowcast-$service:$VERSION"
  docker buildx imagetools inspect --raw "$reference" >"$tmp/$service.json" || { echo "Public image is unavailable: $reference" >&2; exit 1; }
  jq -e 'any(.manifests[]?; .platform.os == "linux" and .platform.architecture == "amd64") or (.config.platform.os == "linux" and .config.platform.architecture == "amd64")' "$tmp/$service.json" >/dev/null || { echo "Image lacks linux/amd64: $reference" >&2; exit 1; }
  docker buildx imagetools inspect "$reference" 2>/dev/null | awk '/^Digest:/ {print $2; exit}' >"$tmp/$service.digest"
  grep -Eq '^sha256:[0-9a-f]{64}$' "$tmp/$service.digest" || { echo "No manifest digest for $reference" >&2; exit 1; }
done
jq -n --arg version "$VERSION" --argjson platforms '["linux/amd64"]' \
  --arg c "$(cat "$tmp/control.digest")" --arg e "$(cat "$tmp/engine.digest")" --arg a "$(cat "$tmp/analyzer.digest")" --arg b "$(cat "$tmp/bliss.digest")" --arg i "$(cat "$tmp/icecast.digest")" \
  '{version:$version,platforms:$platforms,images:{control:{reference:("ghcr.io/chourmovs/flowcast-control:"+$version),digest:$c},engine:{reference:("ghcr.io/chourmovs/flowcast-engine:"+$version),digest:$e},"audio-daemon":{reference:("ghcr.io/chourmovs/flowcast-analyzer:"+$version),digest:$a},bliss:{reference:("ghcr.io/chourmovs/flowcast-bliss:"+$version),digest:$b},icecast:{reference:("ghcr.io/chourmovs/flowcast-icecast:"+$version),digest:$i}}}'
