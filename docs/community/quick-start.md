# Quick start

This beta requires linux/amd64, Docker Engine with Compose v2, 4 GB RAM, 10 GB free disk, and free TCP ports 8080 and 8010. Review and run the tagged installer shown in the repository README with `sudo bash`; the script itself never escalates privileges or installs Docker.

```bash
curl -fsSL \
  https://raw.githubusercontent.com/chourmovs/FlowCast-Community/vVERSION/install.sh \
  | sudo bash -s -- --version VERSION
```

It installs into `/opt/flowcast`, verifies the archive checksum and release version, creates a mode-`0600` `.env`, pulls images, and explicitly waits for `storage-init`, `icecast`, `bliss`, `control`, `engine`, and `audio-daemon`. Open the interface at `http://localhost:8080` and Icecast at `http://localhost:8010`.

An existing `.env` is never overwritten. Update it with `sudo /opt/flowcast/scripts/community/update.sh --version VERSION`, or back up and deliberately remove/restore the old installation.

Docker control is optional: append `--docker-control` only after reviewing the root-equivalent Docker socket risk. Diagnose a failed startup with `sudo /opt/flowcast/scripts/community/doctor.sh`; uninstall with `sudo /opt/flowcast/scripts/community/uninstall.sh` and add `--purge-data` only when permanent deletion is intended.

## Functional streaming qualification

On a clean Linux/amd64 host, install Docker Engine and Compose v2, download and review the tagged installer, and run it once without `--docker-control`. Import operator-owned or freely licensed audio through the UI. If a local test tone is preferable, generate one without committing media:

```bash
sudo /opt/flowcast/scripts/community/test-runtime-stream.sh --generate-fixture /tmp/flowcast-fixture.wav
# Import /tmp/flowcast-fixture.wav, configure/schedule it, then:
sudo /opt/flowcast/scripts/community/test-runtime-stream.sh --mount /stream
```

The test waits for the completed initializer and healthy services, checks both HTTP APIs and the configured mount, consumes audio, checks restart counts and fresh runtime state, and rejects recent persistent engine/Icecast failures. Repeat the standard installation on a fresh host without extra flags; a successful install must report `docker_control=PASS`. A missing/non-Unix socket, unsupported `stat`, or in-container permission/API failure is an installation NO-GO. Only an explicit `--no-docker-control` installation reports `docker_control=DISABLED` and omits Docker socket variables.

## RC6 defaults

The standard one-liner needs no Docker Control flag. Docker Control is enabled, the Unix socket and its GID are detected, and absence/inaccessibility is a hard error. Pass `--no-docker-control` only to install without Start/Stop/Restart support. Socket access is root-equivalent.

The web/player endpoint is port 8080 and the direct Icecast endpoint is port 8010. Container-to-container traffic never uses 8010: `control` uses `icecast:8000`. Public player links are same-origin relative unless the optional `FLOWCAST_PUBLIC_URL` reverse-proxy override is set. The station mount is configured only in `config.yml`.

The completion message gives local/LAN UI, proxy and direct stream URLs, credential location, Docker Control result, and the portable `doctor.sh` command; it never prints credentials.
