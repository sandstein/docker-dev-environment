"""Unit tests for tools/generate.py (run with: python3 -m unittest discover -s tests)."""

import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

import yaml

GENERATOR = Path(__file__).resolve().parent.parent / "tools" / "generate.py"

TEMPLATE = """\
{{name}}:
  container_name: {{name}}
  build:
    context: docker/{{family}}
    args:
      USER_ID: ${USER_ID}
  ports:
    - "{{port}}:80"
    - "127.0.0.1:${{{env_prefix}}_PORT}:81"
  x-binds:
    - vhosts:/var/www/vhosts
    - config/{{name}}/etc:/etc/web
    - $SSH_BASE:/home/web/.ssh
    - ${SECRETS_BASE:-./config/no-secrets}:/home/web/.secrets:ro
"""

STATIC = """\
tool:
  image: example/tool:1.0
  container_name: tool
"""


class GenerateTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        (self.root / "templates").mkdir()
        (self.root / "templates" / "web.yml").write_text(TEMPLATE)
        (self.root / "templates" / "tools.yml").write_text(STATIC)

    def tearDown(self):
        self.tmp.cleanup()

    def catalog(self, text):
        (self.root / "services.yml").write_text(textwrap.dedent(text))

    def generate(self, *args):
        return subprocess.run(
            [sys.executable, str(GENERATOR), "--root", str(self.root), *args],
            capture_output=True, text=True,
        )

    def load(self, name):
        return yaml.safe_load((self.root / "compose" / name).read_text())

    def test_renders_versions_binds_and_base_image(self):
        self.catalog("""
            families:
              web:
                versions:
                  "10": {image: "example/web:1.0", port: 8010}
                  "20":
                    image: "example/web:2.0"
                    port: 8020
                    binds: ["data/web-20:/data"]
                    overrides: {command: serve, ports: ["9020:80"]}
              tools:
        """)
        result = self.generate()
        self.assertEqual(result.returncode, 0, result.stderr)

        services = self.load("web.yml")["services"]
        self.assertEqual(list(services), ["web-10", "web-20"])

        web10 = services["web-10"]
        self.assertEqual(web10["build"], {
            "context": "docker/web",
            "args": {"BASE_IMAGE": "example/web:1.0", "USER_ID": "${USER_ID}"},
        })
        self.assertEqual(web10["ports"], ["8010:80", "127.0.0.1:${WEB_10_PORT}:81"])
        self.assertNotIn("x-binds", web10)
        self.assertEqual(web10["volumes"][1], {
            "type": "bind",
            "source": "${DOCKER_VOLUME_BASE_PATH}/config/web-10/etc",
            "target": "/etc/web",
            "bind": {"create_host_path": False},
        })
        self.assertEqual(web10["volumes"][2]["source"], "$SSH_BASE")
        self.assertEqual(web10["volumes"][3], {
            "type": "bind",
            "source": "${SECRETS_BASE:-./config/no-secrets}",
            "target": "/home/web/.secrets",
            "read_only": True,
            "bind": {"create_host_path": False},
        })

        web20 = services["web-20"]
        self.assertEqual(web20["command"], "serve")
        self.assertEqual(web20["ports"], ["9020:80"])
        self.assertEqual(web20["volumes"][-1]["target"], "/data")

        self.assertIn("tool", self.load("tools.yml")["services"])

        root = yaml.safe_load((self.root / "docker-compose.yml").read_text())
        self.assertEqual(root["include"], [
            {"path": "compose/web.yml", "project_directory": "."},
            {"path": "compose/tools.yml", "project_directory": "."},
        ])
        self.assertIn("app-tier", root["networks"])

        tsv = (self.root / "compose" / "services.tsv").read_text().splitlines()
        self.assertEqual(tsv, [
            "web-10\t1\tconfig/web-10/etc",
            "web-20\t1\tconfig/web-20/etc:data/web-20",
            "tool\t0\t",
        ])

    def test_check_detects_outdated_and_stale_files(self):
        self.catalog("""
            families:
              web:
                versions:
                  "10": {image: "example/web:1.0", port: 8010}
        """)
        self.assertEqual(self.generate().returncode, 0)
        self.assertEqual(self.generate("--check").returncode, 0)

        (self.root / "compose" / "web.yml").write_text("changed")
        (self.root / "compose" / "old.yml").write_text("services: {}")
        result = self.generate("--check")
        self.assertEqual(result.returncode, 1)
        self.assertIn("compose/web.yml", result.stderr)
        self.assertIn("compose/old.yml", result.stderr)

        self.assertEqual(self.generate().returncode, 0)
        self.assertFalse((self.root / "compose" / "old.yml").exists())

    def test_missing_placeholder_value_fails(self):
        self.catalog("""
            families:
              web:
                versions:
                  "10": {image: "example/web:1.0"}
        """)
        result = self.generate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("{{port}} has no value", result.stderr)

    def test_untagged_image_fails(self):
        self.catalog("""
            families:
              web:
                versions:
                  "10": {image: "example/web", port: 8010}
        """)
        result = self.generate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("needs an explicit tag", result.stderr)

    def test_duplicate_service_fails(self):
        (self.root / "templates" / "more.yml").write_text(STATIC)
        self.catalog("""
            families:
              tools:
              more:
        """)
        result = self.generate()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("already defined", result.stderr)


if __name__ == "__main__":
    unittest.main()
