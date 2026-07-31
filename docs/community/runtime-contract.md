# Runtime contract

| Service | DNS | Port | Health |
|---|---|---:|---|
| control | `control` | 8080 | `GET /health` |
| engine | `engine` | 8081 | `GET /health` |
| analyzer | `analyzer` | 8082 | `GET /health` |
| bliss | `bliss` | 8083 | `GET /health` |
| icecast | `icecast` | 8000 | `GET /status-json.xsl` |

Health endpoints return JSON `{"status":"healthy|degraded|unhealthy","version":"semver","checks":{}}`; unknown fields must be ignored. Playback history records use `{"track_id":"string","started_at":"RFC3339","ended_at":"RFC3339|null","reason":"string"}`. The control plane owns authentication, configuration, scheduling requests, and presentation. The engine owns timing, decoding, transitions, and streaming; no algorithm crosses this boundary. Analyzer and Bliss accept media references available in the `flowcast-media` volume and return JSON metadata.

State uses `flowcast-data`, media uses `flowcast-media`, and Icecast logs use `icecast-logs`. The control plane treats timeouts as degraded state, preserves configuration, reports actionable errors, and retries with bounded backoff; loss of analyzer or Bliss must not invalidate existing analysis. Engine loss stops playout rather than silently substituting browser logic. Docker socket access is off by default.
