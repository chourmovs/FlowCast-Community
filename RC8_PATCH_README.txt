FlowCast-Community RC8 patch
=============================

Purpose
-------
This archive contains only files to add/replace in the FlowCast-Community
repository. It is based on the current main branch observed on 2026-08-07.

Apply
-----
1. Make sure your working tree is clean.
2. Extract this ZIP at the ROOT of FlowCast-Community, preserving paths.
3. Review:
       git diff -- . ':!RC8_PATCH_README.txt'
4. Remove this instruction file before committing:
       rm RC8_PATCH_README.txt

Recommended validation
----------------------
bash -n install.sh
python3 scripts/audit-public-repository.py
python3 scripts/docs/validate_docs.py
python3 -m unittest discover -s tests -v

With Docker/Compose available:
FLOWCAST_DOCKER_GID=0 docker compose --env-file .env.example --env-file version.env -f compose.yml config --quiet
FLOWCAST_DOCKER_GID=0 docker compose --env-file .env.example --env-file version.env -f compose.yml -f compose.docker-control.yml config --quiet
python3 scripts/audit-runtime-contract.py

Website:
cd website
npm ci
npm run build

RC8 runtime deltas covered by this patch
----------------------------------------
- version.env -> 0.1.0-rc.8
- persistent flowcast-backups volume
- /data/flowcast-backups mounted in control and initialized by storage-init
- Icecast log volume at /data/icecast
- same Icecast log volume mounted read-only into control
- statistics session/sample retention defaults (365 / 90 days)
- runtime audit/tests enforce the new contract
- README/docs updated for RC8
- Astro landing page gets a compact RC8 highlights section
- site metadata now mentions widgets, statistics and backup/restore

Important
---------
Do not deploy RC8 service images with the older RC7 Community compose.yml:
backup/restore workers and station statistics depend on the new persistent
mounts shipped in this patch.
