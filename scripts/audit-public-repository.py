#!/usr/bin/env python3
"""Dependency-free policy and credential scanner for the public repository."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


BLOCKED_SUFFIXES = {
    ".db",
    ".sqlite",
    ".sqlite3",
    ".pem",
    ".key",
    ".p12",
    ".mp3",
    ".wav",
    ".flac",
    ".ogg",
    ".so",
    ".dll",
    ".exe",
    ".bin",
}

ALLOWED_BINARY_SUFFIXES = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
    ".ico",
}

SKIP_DIRECTORIES = {
    ".git",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    "dist",
}

PATTERNS = {
    "private key": re.compile(
        r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"
    ),
    "GitHub token": re.compile(
        r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,})\b"
    ),
    "JWT": re.compile(
        r"\beyJ[A-Za-z0-9_-]{10,}\."
        r"[A-Za-z0-9_-]{10,}\."
        r"[A-Za-z0-9_-]{8,}\b"
    ),
    "credential URL": re.compile(
        r"https?://[^\s/:]+:[^\s/@]+@"
    ),
    "sslip domain": re.compile(
        r"\b[\w.-]+\.sslip\.io\b",
        re.IGNORECASE,
    ),
    "service platform variable": re.compile(
        r"\bSERVICE_(?:FQDN|URL)_[A-Z0-9_]+\b"
    ),
    "personal path": re.compile(
        r"(?:/home/[\w.-]+|/Users/[\w.-]+)"
    ),
    "Docker credentials": re.compile(
        r'"auths"\s*:\s*\{|DOCKER_AUTH_CONFIG\s*='
    ),
    "probable secret assignment": re.compile(
        r"(?i)"
        r"\b(?:"
        r"password|passwd|api[_-]?key|secret|token|cookie|"
        r"licen[cs]e[_-]?(?:key|token)"
        r")"
        r"\s*[:=]\s*"
        r"[\"']?"
        r"(?!\$|\{|<|change-me|example|dummy|redacted|false|true)"
        r"[A-Za-z0-9+/_.-]{12,}"
    ),
    "hard-coded IP": re.compile(
        r"(?<![\w.])"
        r"(?!(?:127\.0\.0\.1|0\.0\.0\.0|255\.255\.255\.255)\b)"
        r"(?:\d{1,3}\.){3}\d{1,3}"
        r"(?![\w.])"
    ),
}

TEXT_MAX_BYTES = 2_000_000
IMAGE_MAX_BYTES = 5_000_000


def iter_files(root: Path):
    """Yield repository files while excluding generated and dependency folders."""

    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue

        relative_parts = path.relative_to(root).parts

        if any(part in SKIP_DIRECTORIES for part in relative_parts):
            continue

        yield path


def should_skip_pattern_scan(relative_path: Path) -> bool:
    """Avoid matching scanner patterns and fixtures against themselves."""

    if relative_path == Path("scripts/audit-public-repository.py"):
        return True

    if relative_path.parts[:1] == ("tests",):
        return True

    return False


def audit(root: Path) -> list[str]:
    """Audit repository files and return blocking findings."""

    findings: list[str] = []

    for path in iter_files(root):
        relative_path = path.relative_to(root)
        suffix = path.suffix.lower()
        size = path.stat().st_size

        if path.name.startswith(".env") and path.name != ".env.example":
            findings.append(
                f"{relative_path}: non-example environment file"
            )

        if suffix in BLOCKED_SUFFIXES:
            findings.append(
                f"{relative_path}: blocked extension {path.suffix}"
            )
            continue

        if suffix in ALLOWED_BINARY_SUFFIXES:
            if size > IMAGE_MAX_BYTES:
                findings.append(
                    f"{relative_path}: image exceeds "
                    f"{IMAGE_MAX_BYTES} bytes"
                )

            continue

        if size > TEXT_MAX_BYTES:
            findings.append(
                f"{relative_path}: oversized or unreviewed file"
            )
            continue

        try:
            data = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            findings.append(
                f"{relative_path}: unexpected binary content"
            )
            continue
        except OSError as error:
            findings.append(
                f"{relative_path}: unable to read file: {error}"
            )
            continue

        if should_skip_pattern_scan(relative_path):
            continue

        for name, pattern in PATTERNS.items():
            for match in pattern.finditer(data):
                line_number = data.count(
                    "\n",
                    0,
                    match.start(),
                ) + 1

                findings.append(
                    f"{relative_path}:{line_number}: {name}"
                )

    return findings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Audit a public repository for credentials, "
            "blocked files and unexpected binary content."
        )
    )

    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="repository root to audit",
    )

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()

    if not root.exists():
        print(
            f"ERROR: repository root does not exist: {root}",
            file=sys.stderr,
        )
        return 2

    if not root.is_dir():
        print(
            f"ERROR: repository root is not a directory: {root}",
            file=sys.stderr,
        )
        return 2

    findings = audit(root)

    if findings:
        print("BLOCKING findings:")
        print("\n".join(f"- {finding}" for finding in findings))
        return 1

    audited_count = sum(1 for _ in iter_files(root))

    print(
        f"PASS: audited {audited_count} files; "
        "no blocking findings."
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
