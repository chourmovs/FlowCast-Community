# Architecture

[Repository home](../../README.md) · [Documentation index](../README.md)
The Python control plane provides the authenticated web UI and orchestration API. Separately versioned Rust OCI images provide playout, analysis, and track-similarity processing. Icecast serves streams. The public package contains no engine source and no local `build:` fallback. A private internal Docker network joins services; only control port 8080 is published. Named volumes hold state, media, and Icecast logs.
