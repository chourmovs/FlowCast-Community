# Quick start

Use amd64 or arm64 Linux with Docker Engine, Compose v2, 4 GB RAM, 10 GB free disk, and port 8080. Download a tagged `install.sh` and its source, inspect it, then execute it. The installer verifies the release archive checksum before extraction and never installs Docker or invokes sudo.

For manual setup, copy `.env.example` to `.env`, replace all three example Icecast values with distinct random secrets, set mode `0600`, then run `docker compose --env-file .env config`, `docker compose pull`, and `docker compose up -d`. Open `http://localhost:8080`. Images must exist in GHCR before installation can succeed.
