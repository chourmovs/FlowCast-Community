# Configuration

Copy `.env.example` to `.env`; never commit it. `FLOWCAST_VERSION` pins every image. `FLOWCAST_HTTP_PORT` selects the host control port, authentication remains enabled with `FLOWCAST_AUTH_ENABLED=true`, and `FLOWCAST_PUBLIC_URL` is the operator-facing URL. Set three distinct high-entropy Icecast source, relay, and admin passwords.

`FLOWCAST_DOCKER_CONTROL_ENABLED=false` is the safe default. Standard Compose never mounts the socket. The Coolify/operator override can map a deliberately selected `FLOWCAST_DOCKER_SOCKET`; Docker socket access is effectively root-equivalent and must be enabled only after review. Community needs no licence variables.
