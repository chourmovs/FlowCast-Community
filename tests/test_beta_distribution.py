from pathlib import Path
import re
import unittest

ROOT = Path(__file__).parents[1]


class InstallerContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.install = (ROOT / "install.sh").read_text()

    def test_default_and_override_version(self):
        self.assertIn('VERSION="${FLOWCAST_VERSION:-0.1.0-rc.1}"', self.install)
        self.assertIn('--version)', self.install)

    def test_amd64_only(self):
        self.assertRegex(self.install, r'x86_64\|amd64')
        self.assertIn('currently published for linux/amd64 only', self.install)

    def test_archive_integrity_and_manifest_version(self):
        self.assertIn('flowcast-community-$TAG.tar.gz', self.install)
        self.assertIn('sha256sum -c -', self.install)
        self.assertIn('does not match requested version', self.install)

    def test_existing_install_and_secrets(self):
        self.assertIn('existing FlowCast installation', self.install)
        names = re.findall(r'^ICECAST_(?:SOURCE|RELAY|ADMIN)_PASSWORD=', self.install, re.M)
        self.assertEqual(len(names), 3)
        self.assertIn('chmod 600', self.install)

    def test_override_and_explicit_states(self):
        self.assertIn('compose.docker-control.yml', self.install)
        for service in ('storage-init', 'icecast', 'bliss', 'control', 'engine', 'audio-daemon'):
            self.assertIn(service, self.install)
        self.assertIn('FLOWCAST_START_TIMEOUT:-300', self.install)


class ReleaseContractTests(unittest.TestCase):
    def test_assets_and_manual_publication_gate(self):
        workflow = (ROOT / '.github/workflows/release.yml').read_text()
        for asset in ('flowcast-community-v${{ inputs.version }}.tar.gz', 'checksums.sha256',
                      'images.lock', 'release-manifest.json', 'sbom.spdx.json'):
            self.assertIn(asset, workflow)
        self.assertIn('if: ${{ inputs.publish }}', workflow)

    def test_exact_archive_content_script(self):
        script = (ROOT / 'scripts/release/build-release.sh').read_text()
        for item in ('compose.yml', 'compose.docker-control.yml', '.env.example', 'README.md',
                     'LICENSE', 'install.sh', 'scripts', 'docs', 'VERSION'):
            self.assertIn(item, script)
        self.assertNotIn('git archive', script)

    def test_all_public_images_and_amd64_are_checked(self):
        script = (ROOT / 'scripts/release/inspect-images.sh').read_text()
        for image in ('control', 'engine', 'analyzer', 'bliss', 'icecast'):
            self.assertIn(image, script)
        self.assertIn('linux', script)
        self.assertIn('amd64', script)


if __name__ == '__main__':
    unittest.main()
