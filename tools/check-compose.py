#!/usr/bin/env python3
"""Consistency checks for the dde compose setup.

Runs `docker compose config` with the values from .env.sample (plus a fixed,
fake DOCKER_VOLUME_BASE_PATH) and inspects the fully resolved model, so the
checks work no matter how the compose files are organised.

Exit code 0 when everything is fine, 1 when at least one error was found.

Usage: tools/check-compose.py [--compose-file docker-compose.yml]
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FAKE_BASE = "/dde-volume-base"
NETWORK = "app-tier"

# Services that are alternatives of each other and may therefore publish the
# same host port (they are never started together).
ALTERNATIVES = [
    {"chrome", "chrome-standalone"},
    {"edge", "edge-standalone"},
    {"firefox", "firefox-standalone"},
]

# Host paths below the volume base that several services may share on purpose.
SHARED_PATHS = {"vhosts"}


def read_env_sample(path):
    env = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        env[key.strip()] = value.strip().strip('"')
    return env


def resolve_config(compose_file):
    env = dict(os.environ)
    # never let the developer's own settings leak into the check
    for key in list(env):
        if key.startswith(("DOCKER_", "COMPOSE_")) and key not in ("DOCKER_HOST", "DOCKER_CONFIG", "DOCKER_CONTEXT"):
            del env[key]
    env.update(read_env_sample(ROOT / ".env.sample"))
    env["DOCKER_VOLUME_BASE_PATH"] = FAKE_BASE
    env["HOME"] = "/home/dde"
    env.setdefault("SSH_AUTH_SOCK", "/run/ssh-agent.sock")
    proc = subprocess.run(
        ["docker", "compose", "--project-directory", str(ROOT), "-f", str(compose_file),
         "config", "--format", "json"],
        cwd=ROOT, env=env, capture_output=True, text=True,
    )
    return proc


class Report:
    def __init__(self):
        self.errors = []

    def error(self, where, message):
        self.errors.append(f"{where}: {message}")


def mount_source(mount, volumes):
    """Host path behind a mount, or None if it is not backed by a host path."""
    if mount.get("type") == "bind":
        return mount.get("source")
    if mount.get("type") == "volume" and mount.get("source"):
        opts = (volumes.get(mount["source"]) or {}).get("driver_opts") or {}
        if opts.get("o") == "bind":
            return opts.get("device")
    return None


def owner_of(path):
    """config/<svc>/... or data/<svc>/... below the volume base -> <svc>."""
    if not path or not path.startswith(FAKE_BASE + "/"):
        return None
    parts = path[len(FAKE_BASE) + 1:].split("/")
    if parts[0] in SHARED_PATHS:
        return None
    if parts[0] in ("config", "data") and len(parts) > 1:
        return parts[1]
    return None


def check(model, report):
    services = model.get("services", {})
    volumes = model.get("volumes", {}) or {}
    published = {}

    for name, svc in sorted(services.items()):
        where = f"service {name}"

        if svc.get("container_name", name) != name:
            report.error(where, f"container_name is '{svc['container_name']}', expected '{name}'")

        networks = svc.get("networks") or {}
        if NETWORK not in networks:
            report.error(where, f"not attached to network '{NETWORK}'")
        else:
            aliases = (networks[NETWORK] or {}).get("aliases") or []
            if aliases and name not in aliases:
                report.error(where, f"network aliases {aliases} do not contain '{name}'")

        build = svc.get("build")
        if build:
            context = Path(build["context"])
            dockerfile = context / build.get("dockerfile", "Dockerfile")
            if not context.is_dir():
                report.error(where, f"build context {context} does not exist")
            elif not dockerfile.is_file():
                report.error(where, f"{dockerfile} does not exist")
        elif not svc.get("image"):
            report.error(where, "neither build nor image given")

        targets = set()
        for mount in svc.get("volumes") or []:
            target = mount.get("target", "")
            if not target.startswith("/"):
                report.error(where, f"mount target '{target}' is not absolute (missing ':' in the volume entry?)")
            elif mount.get("type") == "volume" and not mount.get("source"):
                report.error(where, f"anonymous volume at '{target}' (missing source?)")
            if target in targets:
                report.error(where, f"mount target '{target}' used twice")
            targets.add(target)
            owner = owner_of(mount_source(mount, volumes))
            if owner and owner != name:
                report.error(where, f"mounts '{mount_source(mount, volumes)}', which belongs to service '{owner}'")

        for port in svc.get("ports") or []:
            if not port.get("published"):
                report.error(where, f"port {port.get('target')} has an empty published port (unset variable?)")
                continue
            key = (port.get("host_ip", "0.0.0.0"), str(port["published"]), port.get("protocol", "tcp"))
            published.setdefault(key, []).append(name)

    for (host_ip, port, proto), names in sorted(published.items()):
        if len(names) < 2:
            continue
        if any(set(names) <= group for group in ALTERNATIVES):
            continue
        report.error("ports", f"{host_ip}:{port}/{proto} published by {', '.join(names)}")



def check_unused_volumes(report):
    """`docker compose config` drops unused volumes, so look at the raw files."""
    try:
        import yaml
    except ImportError:
        print("warning: PyYAML missing, skipping the unused volume check", file=sys.stderr)
        return
    defined, used = {}, set()
    for path in compose_files():
        model = yaml.safe_load(path.read_text()) or {}
        for name in (model.get("volumes") or {}):
            defined[name] = path
        for svc in (model.get("services") or {}).values():
            for mount in svc.get("volumes") or []:
                if isinstance(mount, str):
                    used.add(mount.split(":", 1)[0])
                elif mount.get("type", "volume") == "volume" and mount.get("source"):
                    used.add(mount["source"])
    for name in sorted(set(defined) - used):
        report.error(f"volume {name}", f"defined in {defined[name].name} but not used by any service")
    # two list entries glued together, e.g. "a_bin:/home/x/binb_composer"
    for path in compose_files():
        model = yaml.safe_load(path.read_text()) or {}
        for svc_name, svc in (model.get("services") or {}).items():
            for mount in svc.get("volumes") or []:
                target = mount.split(":")[1] if isinstance(mount, str) and ":" in mount else ""
                for part in target.split("/"):
                    for name in defined:
                        if part != name and part.endswith(name):
                            report.error(f"service {svc_name}", f"mount target '{target}' ends with volume name '{name}'")


COMPOSE_FILE = ROOT / "docker-compose.yml"


def compose_files():
    files = [COMPOSE_FILE, *sorted((COMPOSE_FILE.parent / "compose").glob("**/*.yml"))]
    return [path for path in files if path.is_file()]


def check_env_sample(report):
    """Every variable used in a compose file must be defined in .env.sample."""
    sample = read_env_sample(ROOT / ".env.sample")
    builtin = {"HOME", "PWD", "SSH_AUTH_SOCK"}
    pattern = re.compile(r"\$\{?([A-Z_][A-Z0-9_]*)")
    for path in compose_files():
        for lineno, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            for var in pattern.findall(line):
                if var not in sample and var not in builtin:
                    report.error(f"{path.name}:{lineno}", f"variable {var} is not defined in .env.sample")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--compose-file", default=str(ROOT / "docker-compose.yml"))
    args = parser.parse_args()
    global COMPOSE_FILE
    COMPOSE_FILE = Path(args.compose_file).resolve()

    report = Report()
    proc = resolve_config(Path(args.compose_file))
    for line in proc.stderr.splitlines():
        if line.strip():
            report.error("docker compose config", line.strip())
    if proc.returncode == 0:
        check(json.loads(proc.stdout), report)
    check_unused_volumes(report)
    check_env_sample(report)

    if report.errors:
        print(f"{len(report.errors)} compose problem(s) found:", file=sys.stderr)
        for err in report.errors:
            print(f"  - {err}", file=sys.stderr)
        return 1
    print("compose check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
