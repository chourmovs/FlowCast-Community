# Runtime contract

The canonical distribution has six Compose services: `storage-init`, `icecast`, `bliss`, `audio-daemon`, `engine`, and `control`. The public HTTP mapping targets control port 8088; Bliss listens on 8090; Icecast listens on 8000. `audio-daemon` uses the analyzer OCI image but is never named `analyzer` as a Compose service.

Persistent state is separated into `flowcast-catalog`, `flowcast-media`, `flowcast-settings`, `flowcast-engine-history`, and `flowcast-analysis`. Docker socket access is absent from the base manifest and exists only in `compose.docker-control.yml`.
