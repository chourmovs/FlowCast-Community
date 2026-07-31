# Troubleshooting

Run `scripts/community/doctor.sh` and inspect `docker compose logs --tail 200 SERVICE`; redact identifiers before sharing. Verify daemon access, disk, port 8080, DNS among containers, distinct secrets, and image availability. Do not paste `.env`, database contents, stream credentials, cookies, or licence credentials into an issue.
