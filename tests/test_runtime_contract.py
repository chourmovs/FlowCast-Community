from copy import deepcopy
import importlib.util
from pathlib import Path
import shutil
import subprocess
import tarfile
import unittest


ROOT = Path(__file__).parents[1]
SPEC = importlib.util.spec_from_file_location(
    "runtime_contract", ROOT / "scripts/audit-runtime-contract.py"
)
RUNTIME_CONTRACT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNTIME_CONTRACT)


@unittest.skipUnless(shutil.which("docker"), "Docker Compose is required to render the contract")
class RuntimeContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.main = RUNTIME_CONTRACT.render("compose.yml")
        cls.override = RUNTIME_CONTRACT.render("compose.yml", "compose.docker-control.yml")
        cls.source = (ROOT / "compose.yml").read_text()

    def test_current_contract_passes(self):
        self.assertEqual(RUNTIME_CONTRACT.audit(self.main, self.override, self.source), [])

    def test_retired_health_endpoint_is_rejected(self):
        broken = deepcopy(self.main)
        broken["services"]["audio-daemon"]["healthcheck"]["test"] = [
            "CMD", "curl", "http://localhost:8091/health"
        ]
        errors = RUNTIME_CONTRACT.audit(broken, self.override, self.source)
        self.assertTrue(any("8091/8092" in error for error in errors))

    def test_dependency_cycle_is_rejected(self):
        broken = deepcopy(self.main)
        broken["services"]["control"]["depends_on"] = {"engine": {"condition": "service_healthy"}}
        self.assertTrue(RUNTIME_CONTRACT.find_cycle(broken["services"]))


class ReleaseArchiveRuntimeTests(unittest.TestCase):
    def test_release_archive_contains_current_runtime(self):
        dist = ROOT / "dist"
        self.addCleanup(shutil.rmtree, dist, True)
        dist.mkdir(exist_ok=True)
        (dist / "images.lock").write_text("test fixture\n")
        version = "0.1.0-rc.91"
        subprocess.run(["bash", "scripts/release/build-release.sh", version], cwd=ROOT, check=True)
        archive = dist / f"flowcast-community-v{version}.tar.gz"
        with tarfile.open(archive) as package:
            compose = package.extractfile("./compose.yml").read().decode()
            self.assertEqual(package.extractfile("./VERSION").read().decode().strip(), version)
            self.assertIn(f"FLOWCAST_VERSION={version}", package.extractfile("./.env.example").read().decode())
            self.assertIn(f"FLOWCAST_VERSION={version}", package.extractfile("./versions.env").read().decode())
        self.assertIn("/usr/local/bin/flowcast-analyzer", compose)
        self.assertIn("--healthcheck", compose)
        self.assertNotIn("http://localhost:8091/health", compose)
        self.assertNotIn("http://localhost:8092/health", compose)
        self.assertEqual(compose, (ROOT / "compose.yml").read_text())

    def test_standard_and_opt_in_socket_contract(self):
        source = (ROOT / "compose.yml").read_text()
        override = (ROOT / "compose.docker-control.yml").read_text()
        self.assertNotIn("docker.sock", source)
        self.assertIn("docker.sock", override)
        self.assertIn("FLOWCAST_DOCKER_GID", override)

    def test_stream_smoke_has_success_and_failure_gates(self):
        script = (ROOT / "scripts/community/test-runtime-stream.sh").read_text()
        for check in ("status-json.xsl", "RestartCount", "runtime-state", "Login failed", "ENGINE_ERROR", "stream_test=PASS"):
            self.assertIn(check, script)


if __name__ == "__main__":
    unittest.main()
