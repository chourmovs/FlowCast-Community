import os
from pathlib import Path
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).parents[1]
CHECKER = ROOT / "scripts/release/check-public-images.sh"


class PublicImageCheckerTests(unittest.TestCase):
    def run_checker(self, version="0.1.0-rc.3", *, fail_image="", platform="linux/amd64"):
        with tempfile.TemporaryDirectory() as directory:
            fake_docker = Path(directory) / "docker"
            fake_docker.write_text(textwrap.dedent("""\
                #!/usr/bin/env bash
                if [[ "$1" == logout ]]; then
                  exit "${LOGOUT_STATUS:-0}"
                fi
                reference="${@: -1}"
                if [[ -n "${FAIL_IMAGE:-}" && "$reference" == *"$FAIL_IMAGE"* ]]; then
                  exit 23
                fi
                printf 'Platform: %s\\n' "${FAKE_PLATFORM:-linux/amd64}"
            """))
            fake_docker.chmod(0o755)
            environment = os.environ | {
                "PATH": f"{directory}:{os.environ['PATH']}",
                "FAIL_IMAGE": fail_image,
                "FAKE_PLATFORM": platform,
            }
            return subprocess.run(
                [str(CHECKER), version],
                cwd=ROOT,
                env=environment,
                text=True,
                capture_output=True,
                check=False,
            )

    def test_invalid_version_is_rejected_before_docker(self):
        result = self.run_checker("0.1.0")
        self.assertEqual(result.returncode, 2)
        self.assertIn("FAIL version", result.stderr)

    def test_missing_image_returns_failure(self):
        result = self.run_checker(fail_image="flowcast-analyzer")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("FAIL flowcast-analyzer", result.stderr)
        self.assertIn("4/5 public images verified", result.stdout)

    def test_all_five_public_amd64_images_pass(self):
        result = self.run_checker()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count("PASS flowcast-"), 5)
        self.assertIn("5/5 public images verified", result.stdout)

    def test_platform_error_propagates_as_nonzero(self):
        result = self.run_checker(platform="linux/arm64")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stderr.count("missing linux/amd64"), 5)


if __name__ == "__main__":
    unittest.main()
