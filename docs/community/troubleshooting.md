# Troubleshooting

Run `sudo /opt/flowcast/scripts/community/doctor.sh`. It checks Docker and Compose, disk, configured ports, release files, five images, all six services, `/api/health`, and Icecast status without displaying secret values.

For details, run `docker compose --env-file /opt/flowcast/.env -f /opt/flowcast/compose.yml ps` and `logs --tail 50 SERVICE`; add `-f /opt/flowcast/compose.docker-control.yml` when Docker control is enabled. Check port conflicts with `ss -ltn`, daemon access with `docker info`, and disk with `df -h /opt/flowcast`.

The installer has a single five-minute startup deadline and reports logs for services that did not reach their expected state. Never paste `.env`, stream credentials, cookies, media, or databases into an issue.
