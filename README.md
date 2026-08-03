# Self-hosted radio automation, scheduling and playout — under your control.

**FlowCast is a self-hosted radio automation, scheduling and playout platform built for operators who want full control over their broadcast infrastructure.** Community packages the authenticated control plane and versioned broadcast services for an operator-managed Linux host; the service images are separately licensed and this repository does not claim that their source is open.

**Automate · Broadcast · Stay independent**

[Quick Start](#installation) · [Documentation](docs/README.md) · [Releases](https://github.com/chourmovs/FlowCast-Community/releases) · [Security](SECURITY.md) · [Support](SUPPORT.md)

[![Release](https://img.shields.io/github/v/release/chourmovs/FlowCast-Community?display_name=tag)](https://github.com/chourmovs/FlowCast-Community/releases) [![Validate](https://github.com/chourmovs/FlowCast-Community/actions/workflows/validate.yml/badge.svg)](https://github.com/chourmovs/FlowCast-Community/actions/workflows/validate.yml) [![License: MIT](https://img.shields.io/badge/repository-MIT-22D3EE.svg)](LICENSE) ![Platform: Linux amd64](https://img.shields.io/badge/platform-linux%2Famd64-8B5CF6)

## Product preview

No product image is committed yet: this documentation runner cannot launch a verified rc.7 instance, and the repository will not substitute an invented mockup. The first preview will be a sanitized capture of the authenticated dashboard and Now Playing view produced through the [real-instance capture procedure](docs/assets/screenshots/README.md).

# Self-hosted radio automation that thinks beyond the playlist

**FlowCast is a self-hosted radio automation, scheduling and intelligent playout platform for operators who want complete control over both their infrastructure and their station's sound.**

Unlike traditional radio automation stacks built around a general-purpose Liquidsoap scripting layer, FlowCast uses a dedicated playout engine designed specifically for automated broadcasting, fine-grained transitions and music-aware programming.

Configure your station. Shape its sound. Let FlowCast handle the playout.

**Automate · Transition · Broadcast · Stay independent**

[Quick Start](#installation) · [Documentation](docs/README.md) · [Releases](https://github.com/chourmovs/FlowCast-Community/releases) · [Security](SECURITY.md) · [Support](SUPPORT.md)

---

## Why FlowCast is different

FlowCast is not simply a web interface placed in front of a generic streaming script. Its scheduler, audio analysis and playout engine are designed together as a complete radio automation system.

### No Liquidsoap scripting layer

Many self-hosted radio platforms ultimately require operators to understand, generate or troubleshoot Liquidsoap scripts.

FlowCast takes a different approach.

Its dedicated Rust playout engine receives an explicit station configuration and executes the broadcast directly. Operators configure playlists, scheduling, transitions and station behaviour without maintaining a separate domain-specific playout script.

This means:

* no Liquidsoap syntax to learn;
* no generated script to inspect when something behaves unexpectedly;
* no fragile custom script fragments to maintain across upgrades;
* fewer abstraction layers between the control interface and the audio engine;
* a playout runtime developed specifically around FlowCast's scheduling model.

You configure the desired broadcast behaviour—not the implementation script behind it.

### Transitions are a first-class feature

FlowCast treats the transition between two tracks as part of the programming, not as a fixed crossfade added at the end of the audio pipeline.

Transition parameters can be tuned to shape the identity of the station:

* fade-in and fade-out timing;
* overlap duration;
* bridge duration;
* track exit timing;
* queue and prefetch behaviour;
* transition-aware playout decisions.

The objective is not merely to avoid silence. It is to give operators precise control over how one track hands over to the next.

A continuous radio stream should sound programmed—not shuffled.

### Music-aware programming

Traditional rotation systems primarily select tracks from rules, categories, clocks or random pools. FlowCast can also use information extracted from the audio itself.

#### BPM-driven programming

FlowCast can use track tempo as part of the scheduling and selection process.

BPM-aware programming helps build sequences with more coherent changes in pace and energy, reducing abrupt transitions between tracks that satisfy the same playlist rules but do not naturally follow each other.

Tempo does not replace editorial rules. It adds a musical signal to them.

#### Bliss-driven programming with FlowCast Pro

FlowCast Pro can extend music-aware selection using acoustic similarity features produced through Bliss analysis.

Instead of considering only metadata such as genre, artist or BPM, Bliss-driven selection can compare characteristics extracted directly from the audio signal to identify tracks that are musically compatible.

This creates the foundation for:

* similarity-aware track selection;
* smoother musical progression;
* more coherent automatic sequencing;
* reduced repetition of tracks with overly similar profiles;
* programming driven by both editorial constraints and acoustic distance.

Community provides the autonomous broadcast foundation. Pro adds deeper music-intelligence capabilities without replacing the operator's programming strategy.

---

## A different approach to radio automation

| Conventional script-centric stack                                 | FlowCast                                                                    |
| ----------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Playout behaviour expressed through a separate scripting language | Dedicated playout engine controlled through explicit FlowCast configuration |
| Transitions commonly reduced to a global crossfade                | Fine-grained transition timing, overlap and bridge controls                 |
| Rotation primarily based on metadata, clocks and random selection | Scheduling enriched with BPM-aware selection                                |
| Advanced musical sequencing requires custom logic                 | Optional Bliss-driven acoustic similarity with FlowCast Pro                 |
| Troubleshooting often requires inspecting generated scripts       | Runtime state, history, logs and diagnostics exposed through FlowCast       |
| Changes may require editing or regenerating playout code          | Station behaviour configured without writing playout scripts                |

FlowCast does not try to hide a traditional radio stack behind another abstraction layer. It replaces that layer with a purpose-built scheduling and playout architecture.

---

## Core capabilities

### FlowCast Community

The Community edition provides the complete autonomous broadcast path:

* authenticated station control;
* media library management;
* playlist creation and organization;
* scheduled programming;
* BPM-aware music selection;
* configurable track transitions;
* dedicated Rust playout engine;
* audio analysis;
* Icecast stream delivery;
* Now Playing and upcoming-track information;
* engine history;
* backup and restore;
* controlled updates and rollback;
* installation diagnostics through `doctor.sh`;
* optional Docker Control for service operations.

Community starts and broadcasts without a paid licence and without a mandatory remote licence-service request.

### FlowCast Pro

FlowCast Pro builds on the Community broadcast foundation with optional advanced capabilities, including:

* Bliss-driven acoustic similarity;
* music-aware sequence optimization;
* advanced transition and programming strategies;
* additional operational or fleet-oriented services as they become officially documented;
* commercial licensing and support options.

Pro remains optional. The Community broadcast path must continue operating independently if Pro is not configured or its licensing service is unavailable.


## Screenshots

Real screenshots will be published only after capture from a qualified Community instance and a sanitization review. Until then, the gallery records its intended coverage without committing stand-in graphics.

| Planned capture | What it will demonstrate | Status |
| --- | --- | --- |
| Dashboard and Now Playing | Authenticated overview and current playout state | Awaiting verified rc.7 capture |
| Programming and Upcoming | Schedule configuration and interpreted upcoming sequence | Awaiting verified rc.7 capture |
| Playlists and library | Playlist organization and imported media | Awaiting verified rc.7 capture |
| Supervision and service controls | Health, sanitized logs and Docker Control operations | Awaiting verified rc.7 capture |

See the [capture and publication procedure](docs/assets/screenshots/README.md).

## Community Edition

Community works without a paid licence, starts and broadcasts without a mandatory remote licence call, retains the essential broadcast path, and receives best-effort community support. Pro is optional and separately licensed; no undefined Pro feature is promised. Read [Community versus Pro](docs/community/community-vs-pro.md).

## Installation

**Requirements:** Linux amd64, Docker Engine, Docker Compose v2, 2 CPU cores, at least 4 GB RAM, 10 GB free disk plus media, and free TCP ports **8080** (control/player proxy) and **8010** (direct Icecast).

```bash
curl -fsSL https://raw.githubusercontent.com/chourmovs/FlowCast-Community/v0.1.0-rc.7/install.sh | sudo bash -s -- --version 0.1.0-rc.7
```

The tagged rc.7 command above remains the currently validated installation command while rc.7 is prepared. The installer writes `/opt/flowcast`, generates credentials, pulls versioned images and waits for service health. It does not install Docker.

> **Security note:** the default rc.7 install enables Docker Control. Mounting the Docker socket is equivalent to granting root-level host control to the container. Use `--no-docker-control` to opt out, and never expose the control UI to untrusted users. See [Security](SECURITY.md).

## First broadcast

1. Run the tagged installer above.
2. Open `http://localhost:8080` and sign in with the locally generated credentials.
3. Import operator-owned or freely licensed audio.
4. Create or select a playlist.
5. Configure its programming in the authenticated interface.
6. Start playout (Docker Control must be enabled for UI service controls).
7. Listen at `/listen/test.mp3` through the control origin or `http://HOST:8010/test.mp3` directly.
8. Verify the installation with `sudo /opt/flowcast/scripts/community/doctor.sh`.

Follow the complete [first broadcast guide](docs/how-to/first-broadcast.md).

## Architecture

```mermaid
flowchart TD
  B[Browser] -->|authenticated control| C[FlowCast Control]
  C -->|orchestration| S[Scheduler]
  S --> E[Playout Engine]
  C --> A[Audio Analyzer]
  A --> BL[Bliss similarity]
  E -->|audio| I[Icecast distribution]
  I --> L[Listeners]
  DB[(Catalog, settings, history)] --> C
  M[(Operator media)] --> A
  M --> E
```

Control, orchestration, analysis, audio playout, distribution and named-volume storage are isolated roles. Details are in [Architecture](docs/community/architecture.md).

## Community versus Pro

| Community | Pro |
| --- | --- |
| Autonomous broadcast path; no paid licence or mandatory licensing service | Optional, separate commercial licence |
| Essential control, scheduling, playout, streaming and operations | May add separately documented advanced functions or services |
| Best-effort community support | Commercial terms apply only when explicitly offered |
| Continues operating if an optional Pro licensing service is unavailable | Pro entitlement failure must not interrupt Community broadcasting |

## Documentation

- **Getting started:** [Quick start](docs/community/quick-start.md), [first broadcast](docs/how-to/first-broadcast.md)
- **Broadcasting:** [Import music](docs/how-to/import-music.md), [playlists](docs/how-to/create-playlist.md), [programming](docs/how-to/schedule-programming.md)
- **Operations:** [Backup, update and rollback](docs/how-to/backup-update-rollback.md), [Docker Control](docs/how-to/docker-control.md)
- **Security:** [Security policy](SECURITY.md), [reverse proxy and TLS](docs/how-to/reverse-proxy-tls.md)
- **Architecture:** [System architecture](docs/community/architecture.md), [runtime contract](docs/community/runtime-contract.md)
- **Troubleshooting:** [Stream troubleshooting](docs/how-to/troubleshoot-stream.md), [known limitations](docs/community/known-limitations.md)

Browse the complete [documentation index](docs/README.md).

## Legal and licensing

Repository scripts and documentation are MIT licensed. FlowCast Community OCI images use the licence declared in their published image metadata; third-party components retain their own licences; Pro uses separate commercial terms; and trademark rights are separate. Review the [licensing guide](docs/legal/licensing.md), [third-party notices](THIRD_PARTY_NOTICES.md), [trademarks](TRADEMARKS.md), [privacy](PRIVACY.md) and [disclaimer](DISCLAIMER.md). The software is supplied without warranty and operators remain responsible for infrastructure, data, broadcasts and applicable rights.

## Built with

FlowCast's distributed runtime uses Python, Rust, FastAPI, NiceGUI, GStreamer, FFmpeg, Icecast, bliss-audio, SQLite and Docker. Each remains an independent project under its own terms.

## Acknowledgements

We thank the maintainers and contributors of the technologies that make self-hosted broadcasting possible. See [Acknowledgements](ACKNOWLEDGEMENTS.md) and [Third-party notices](THIRD_PARTY_NOTICES.md); no third-party affiliation or endorsement is implied.

## Contributing and support

Use [issues](https://github.com/chourmovs/FlowCast-Community/issues) for reproducible sanitized bugs and feature requests, and [Discussions](https://github.com/chourmovs/FlowCast-Community/discussions) if enabled for community questions. Read [Contributing](CONTRIBUTING.md) and [Support](SUPPORT.md). Report vulnerabilities only through [private security reporting](SECURITY.md)—never in a public issue.
