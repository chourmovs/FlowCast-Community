# Quick start

This beta requires linux/amd64, Docker Engine with Compose v2, 4 GB RAM, 10 GB free disk, and free TCP ports 8080 and 8010. Review and run the tagged installer shown in the repository README with `sudo bash`; the script itself never escalates privileges or installs Docker.

It installs into `/opt/flowcast`, verifies the archive checksum and release version, creates a mode-`0600` `.env`, pulls images, and explicitly waits for `storage-init`, `icecast`, `bliss`, `control`, `engine`, and `audio-daemon`. Open the interface at `http://localhost:8080` and Icecast at `http://localhost:8010`.

An existing `.env` is never overwritten. Update it with `sudo /opt/flowcast/scripts/community/update.sh --version VERSION`, or back up and deliberately remove/restore the old installation.

Docker control is optional: append `--docker-control` only after reviewing the root-equivalent Docker socket risk. Diagnose a failed startup with `sudo /opt/flowcast/scripts/community/doctor.sh`; uninstall with `sudo /opt/flowcast/scripts/community/uninstall.sh` and add `--purge-data` only when permanent deletion is intended.
