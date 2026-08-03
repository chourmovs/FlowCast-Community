# Troubleshoot a stream

[Repository home](../../README.md) · [Documentation index](../README.md) · [Previous guide](docker-control.md)

## Objective

Diagnose missing or unhealthy listener audio without exposing secrets.

## Prerequisites

Local administrator access and the affected mount/time recorded.

## Procedure

1. Run `sudo /opt/flowcast/scripts/community/doctor.sh`.
2. Inspect status with `docker compose --env-file /opt/flowcast/.env -f /opt/flowcast/compose.yml ps`; add the Docker Control override only when enabled.
3. Inspect a relevant service with the documented pattern `docker compose --env-file /opt/flowcast/.env -f /opt/flowcast/compose.yml logs --tail 50 SERVICE`.
4. Check `ss -ltn`, `docker info`, and `df -h /opt/flowcast`.
5. Compare the proxied `/listen/test.mp3` path with the direct host port 8010 endpoint and sanitize every result before sharing.

## Expected result

The failing layer—schedule, engine, Icecast, proxy, port or capacity—is identified without revealing credentials.

## Verification

After remediation, confirm audio consumption and a `RESULT=PASS` diagnostic.

## Troubleshooting

Check recent engine/Icecast failures, mount configuration and host port conflicts. Share only minimal redacted logs in an issue.

## Rollback

Undo only the specific configuration change under test. Restore a known compatible backup if persisted configuration was damaged.

## Related documentation

- [Quick start](../community/quick-start.md)
- [Runtime contract](../community/runtime-contract.md)
- [Security policy](../../SECURITY.md)
