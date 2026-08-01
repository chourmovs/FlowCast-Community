#!/usr/bin/env bash
set -uo pipefail

VERSION="${1:-}"
if [[ ! "$VERSION" =~ ^0\.1\.0-rc\.[0-9]+$ ]]; then
  echo 'FAIL version must match 0.1.0-rc.<number>' >&2
  exit 2
fi

command -v docker >/dev/null || { echo 'FAIL docker is required' >&2; exit 127; }
docker logout ghcr.io >/dev/null 2>&1 || true

images=(flowcast-control flowcast-engine flowcast-analyzer flowcast-bliss flowcast-icecast)
passed=0
failed=0

for image in "${images[@]}"; do
  reference="ghcr.io/chourmovs/$image:$VERSION"
  if output="$(docker buildx imagetools inspect "$reference" 2>&1)"; then
    if grep -Eq '(^|[[:space:]/])linux/amd64([[:space:]]|$)' <<<"$output"; then
      printf 'PASS %-18s linux/amd64\n' "$image"
      ((passed += 1))
    else
      printf 'FAIL %-18s missing linux/amd64\n' "$image" >&2
      ((failed += 1))
    fi
  else
    printf 'FAIL %-18s unavailable or private\n' "$image" >&2
    ((failed += 1))
  fi
done

printf '\n%d/5 public images verified\n' "$passed"
((failed == 0))
