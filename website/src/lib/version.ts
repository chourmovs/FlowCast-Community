import fs from 'node:fs';
import path from 'node:path';

const VERSION_PATTERN =
  /^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z][0-9A-Za-z.-]*)?$/;

function resolveRepositoryRoot(): string {
  return path.resolve(process.cwd(), '..');
}

function readVersionEnvironment(): string {
  const versionPath = path.join(
    resolveRepositoryRoot(),
    'version.env',
  );

  const content = fs.readFileSync(
    versionPath,
    'utf-8',
  );

  const matches = content
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) =>
      line.startsWith('FLOWCAST_VERSION='),
    );

  if (matches.length !== 1) {
    throw new Error(
      'version.env must contain exactly one FLOWCAST_VERSION assignment',
    );
  }

  const version = matches[0]
    .split('=', 2)[1]
    .trim();

  if (!VERSION_PATTERN.test(version)) {
    throw new Error(
      `Invalid FLOWCAST_VERSION: ${version}`,
    );
  }

  return version;
}

export const flowcastVersion =
  readVersionEnvironment();

export const flowcastTag =
  `v${flowcastVersion}`;

export const installCommand =
  `curl -fsSL https://raw.githubusercontent.com/` +
  `chourmovs/FlowCast-Community/${flowcastTag}/install.sh` +
  ` | sudo bash -s -- --version ${flowcastVersion}`;
