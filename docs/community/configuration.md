# Configuration

Configuration is stored in `/opt/flowcast/.env` with permissions `0600`. `FLOWCAST_HTTP_PORT` changes the interface host port (8080 by default), `FLOWCAST_STREAM_PORT` changes Icecast (8010), and `FLOWCAST_PUBLIC_URL` must match the URL users visit. Keep authentication enabled and never print or share the three independent Icecast passwords.

After changing ports, run `docker compose --env-file .env -f compose.yml up -d` and allow the new ports through the host firewall. Internal ports are fixed by the runtime contract: control uses 8088, Bliss uses 8090, and Icecast uses 8000.

`FLOWCAST_DOCKER_CONTROL_ENABLED=false` is the safe default. To enable it, set the value to `true` and always use both `compose.yml` and `compose.docker-control.yml`. The operator scripts select that override automatically. Mounting `/var/run/docker.sock` gives the control container effectively root-level control of the host.
