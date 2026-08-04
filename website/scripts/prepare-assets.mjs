import { cp, mkdir, rm, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const websiteDirectory = path.resolve(scriptDirectory, '..');
const repositoryDirectory = path.resolve(websiteDirectory, '..');
const sourceDirectory = path.join(repositoryDirectory, 'docs', 'assets', 'screenshots');
const destinationDirectory = path.join(websiteDirectory, 'public', 'screenshots');

async function assertDirectory(directory) {
  let info;

  try {
    info = await stat(directory);
  } catch (error) {
    throw new Error(`Screenshot source directory is unavailable: ${directory}`, {
      cause: error,
    });
  }

  if (!info.isDirectory()) {
    throw new Error(`Expected a directory: ${directory}`);
  }
}

async function main() {
  await assertDirectory(sourceDirectory);
  await rm(destinationDirectory, { recursive: true, force: true });
  await mkdir(destinationDirectory, { recursive: true });
  await cp(sourceDirectory, destinationDirectory, { recursive: true });

  console.log(`Copied FlowCast screenshots from ${sourceDirectory}`);
  console.log(`Generated public assets in ${destinationDirectory}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
