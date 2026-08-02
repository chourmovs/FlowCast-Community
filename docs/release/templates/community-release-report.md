# FlowCast Community Release Report

## Identification

- Version:
- Date:
- FlowCast commit:
- FlowCast-Community commit:
- Operator:

## Images

| Image | Digest | Anonymous pull | linux/amd64 |
|---|---|---|---|
| control | | PASS / FAIL | PASS / FAIL |
| engine | | PASS / FAIL | PASS / FAIL |
| analyzer | | PASS / FAIL | PASS / FAIL |
| bliss | | PASS / FAIL | PASS / FAIL |
| icecast | | PASS / FAIL | PASS / FAIL |

Anonymous image gate: GO / NO-GO

## Workflows

| Repository | Workflow | Run | Result |
|---|---|---|---|
| FlowCast | FlowCast release candidate | | |
| FlowCast-Community | Community prerelease dry-run | | |
| FlowCast-Community | Community prerelease publish | | |

The publish row must remain `NOT RUN` until every qualification gate below is GO.

## Dry-run artifacts

- Archive version audit (only the requested RC): PASS / FAIL
- `sha256sum -c checksums.sha256`: PASS / FAIL
- `release-manifest.json` version, commit and archive digest: PASS / FAIL
- `images.lock` references and immutable digests: PASS / FAIL
- `sbom.spdx.json` present and readable: PASS / FAIL
- Forbidden files or secrets absent from archive: PASS / FAIL

## Fresh installation

- OS:
- Architecture:
- Docker:
- Compose:
- Installation result:
- Control health:
- Engine health:
- Analyzer health:
- Bliss health:
- Icecast health:
- Streaming test:

### Standard mode (Docker Control disabled)

- Frontend accessible: PASS / FAIL
- UI explicitly reports Docker Control disabled: PASS / FAIL
- Engine is not reported as missing: PASS / FAIL
- Default playlist available: PASS / FAIL
- Station configurable: PASS / FAIL
- Icecast mount present and stream carries data: PASS / FAIL
- `Login failed` absent: PASS / FAIL

### Docker Control opt-in (second clean install)

- Installed with `--docker-control`: PASS / FAIL
- Docker ping from control: PASS / FAIL
- Engine detected without ambiguous/stale containers: PASS / FAIL
- Stop: PASS / FAIL
- Start: PASS / FAIL
- Restart: PASS / FAIL
- Stream returns after restart: PASS / FAIL
- Configuration retained: PASS / FAIL
- Playlists retained: PASS / FAIL
- Media retained: PASS / FAIL

## Runtime qualification

- `doctor.sh`: PASS / FAIL
- `test-runtime-stream.sh`: PASS / FAIL
- Observation start/end (at least ten minutes):
- Unexpected engine restarts absent: PASS / FAIL
- Runtime state recent: PASS / FAIL
- History database readable: PASS / FAIL
- Now Playing consistent with Icecast: PASS / FAIL
- Upcoming consistent with scheduler: PASS / FAIL
- Secrets absent from logs: PASS / FAIL

## Mandatory NO-GO conditions

| Condition | Observed |
|---|---|
| `Login failed` | YES / NO |
| Healthy engine without Icecast mount | YES / NO |
| Runtime button inoperative | YES / NO |
| Docker Control requested but unavailable | YES / NO |
| Engine restart loop | YES / NO |
| Stream without data | YES / NO |
| Divergent archive versions | YES / NO |
| Data lost after restart | YES / NO |
| Secret exposed | YES / NO |

## Issues

- None / list issues

## Verdict

GO / NO-GO
