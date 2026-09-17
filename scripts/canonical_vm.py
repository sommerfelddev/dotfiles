"""Create and operate the disposable Canonical desktop test VM."""

import argparse
import hashlib
import json
import os
import re
import secrets
import select
import shlex
import shutil
import subprocess
import tarfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STATE = ROOT / "tmp/canonical-vm"
NAME = "canonical-lab"
MARKER = "user.dotfiles-lab"
ISO = "ubuntu-26.04.1-desktop-amd64.iso"
RELEASE = "https://releases.ubuntu.com/26.04/"
SIGNER = "843938DF228D22F7B3742BC0D94AA3F0EFE21092"


def run(*args: str, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def output(*args: str) -> str:
    return subprocess.check_output(args, text=True).strip()


def lxc(*args: str, **kwargs):
    return run("lxc", "--force-local", "--project", "default", *args, **kwargs)


def query(path: str):
    return json.loads(
        output("lxc", "--force-local", "query", path + "?project=default")
    )


def require_owned(instance: dict, owner: str) -> None:
    if (
        instance.get("type") != "virtual-machine"
        or instance.get("config", {}).get(MARKER) != owner
    ):
        raise RuntimeError("Refusing to change an unmarked VM.")


def owner() -> str:
    return (STATE / "owner").read_text().strip()


def checked_instance():
    instance = query("/1.0/instances/" + NAME)
    require_owned(instance, owner())
    return instance


def private_file(path: Path, data: str) -> None:
    with path.open("x", encoding="utf-8") as stream:
        stream.write(data)
    path.chmod(0o600)


def prepare() -> None:
    if os.environ.get("AIBOX"):
        raise RuntimeError("Run the VM workflow outside aibox.")
    run("git", "check-ignore", "-q", "tmp/canonical-vm/secrets/probe", cwd=ROOT)
    if "tmp/" not in (ROOT / ".chezmoiignore").read_text().splitlines():
        raise RuntimeError("The lab directory must be ignored by chezmoi.")
    if STATE.resolve() != STATE or (STATE / "secrets").is_symlink():
        raise RuntimeError("The lab directory must not contain redirected paths.")
    os.umask(0o077)
    STATE.mkdir(parents=True, exist_ok=True, mode=0o700)
    STATE.chmod(0o700)
    if not (STATE / "owner").exists():
        private_file(STATE / "owner", secrets.token_hex(16))
    (STATE / "secrets").mkdir(exist_ok=True, mode=0o700)
    for name in ["login-password", "disk-password"]:
        path = STATE / "secrets" / name
        if not path.exists():
            private_file(path, secrets.token_urlsafe(32))
    key = STATE / "secrets/ssh"
    if not key.exists():
        run("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-C", NAME, "-f", str(key))


def download(name: str, mirror: str = RELEASE) -> None:
    target = STATE / name
    if not target.exists():
        if name == ISO:
            run(
                "aria2c",
                "--continue=true",
                "--max-connection-per-server=8",
                "--split=8",
                "--auto-file-renaming=false",
                "--summary-interval=60",
                "--console-log-level=warn",
                "--dir=" + str(STATE),
                "--out=" + name + ".part",
                mirror.rstrip("/") + "/" + name,
            )
            Path(str(target) + ".part").rename(target)
            return
        run(
            "curl",
            "--fail",
            "--location",
            "--retry",
            "3",
            "--output",
            str(target) + ".part",
            RELEASE + name,
        )
        Path(str(target) + ".part").rename(target)


def verify_iso(mirror: str = RELEASE) -> None:
    for name in ["SHA256SUMS", "SHA256SUMS.gpg"]:
        download(name)
    keyring = STATE / "ubuntu-keyring"
    keyring.mkdir(exist_ok=True, mode=0o700)
    run(
        "gpg",
        "--homedir",
        str(keyring),
        "--batch",
        "--keyserver",
        "hkps://keyserver.ubuntu.com",
        "--recv-keys",
        SIGNER,
    )
    run(
        "gpg",
        "--homedir",
        str(keyring),
        "--batch",
        "--verify",
        str(STATE / "SHA256SUMS.gpg"),
        str(STATE / "SHA256SUMS"),
    )
    expected = next(
        line.split()[0]
        for line in (STATE / "SHA256SUMS").read_text().splitlines()
        if line.split()[-1].lstrip("*") == ISO
    )
    download(ISO, mirror)
    with (STATE / ISO).open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual != expected:
        raise RuntimeError("Ubuntu ISO checksum does not match its signed manifest.")


def autoinstall(password_hash: str, public_key: str, disk_password: str) -> dict:
    return {
        "autoinstall": {
            "version": 1,
            "refresh-installer": {"update": False},
            "early-commands": [
                ["systemd-detect-virt", "--vm", "--quiet"],
                ["bash", "/cdrom/lab/install.sh", "live"],
            ],
            "locale": "en_US.UTF-8",
            "keyboard": {"layout": "us"},
            "timezone": "Europe/Lisbon",
            "identity": {
                "hostname": NAME,
                "username": "canonical-test",
                "realname": "Canonical Test",
                "password": password_hash,
            },
            "storage": {
                "layout": {
                    "name": "lvm",
                    "match": {"path": "/dev/sda"},
                    "password": disk_password,
                    "sizing-policy": "all",
                }
            },
            "ssh": {
                "install-server": True,
                "allow-pw": False,
                "authorized-keys": [public_key],
            },
            "packages": [
                "openssh-server",
                "git",
                "curl",
                "gnome-keyring",
                "libsecret-tools",
                "gnupg",
            ],
            "late-commands": [["bash", "/cdrom/lab/install.sh"]],
            "shutdown": "poweroff",
        }
    }


def boot_config(text: str) -> str:
    patched, count = re.subn(
        r"(linux\s+/casper/vmlinuz[^\n]*?)\s+---", r"\1 autoinstall ---", text
    )
    if not count:
        raise RuntimeError("Unknown Ubuntu installer boot configuration.")
    return re.sub(r"set timeout=\d+", "set timeout=1", patched)


def installer(mirror: str = RELEASE) -> None:
    prepare()
    verify_iso(mirror)
    media = STATE / "media"
    media.mkdir(exist_ok=True, mode=0o700)
    password_hash = (
        subprocess.check_output(
            ["openssl", "passwd", "-6", "-stdin"],
            input=(STATE / "secrets/login-password").read_bytes(),
        )
        .decode()
        .strip()
    )
    config = autoinstall(
        password_hash,
        (STATE / "secrets/ssh.pub").read_text().strip(),
        (STATE / "secrets/disk-password").read_text(),
    )
    (media / "autoinstall.yaml").write_text(json.dumps(config, indent=2))
    run(
        "xorriso",
        "-osirrox",
        "on",
        "-indev",
        str(STATE / ISO),
        "-extract",
        "/boot/grub/grub.cfg",
        str(media / "grub.cfg"),
    )
    (media / "grub.cfg").chmod(0o600)
    (media / "grub.cfg").write_text(boot_config((media / "grub.cfg").read_text()))
    target = STATE / "installer.iso"
    if target.exists():
        raise RuntimeError(
            "Installer already exists; keep it for retries or remove it explicitly."
        )
    run(
        "xorriso",
        "-indev",
        str(STATE / ISO),
        "-outdev",
        str(target) + ".part",
        "-boot_image",
        "any",
        "replay",
        "-map",
        str(media / "grub.cfg"),
        "/boot/grub/grub.cfg",
        "-map",
        str(media / "autoinstall.yaml"),
        "/autoinstall.yaml",
        "-map",
        str(ROOT / "scripts/canonical-vm-install.sh"),
        "/lab/install.sh",
        "-map",
        str(STATE / "secrets/disk-password"),
        "/lab/disk-password",
        "-map",
        str(STATE / "owner"),
        "/lab/owner",
    )
    Path(str(target) + ".part").rename(target)


def create(mirror: str = RELEASE) -> None:
    prepare()
    instances = query("/1.0/instances")
    if any(path.split("?")[0].endswith("/" + NAME) for path in instances):
        checked_instance()
        raise RuntimeError("Lab VM already exists; use start, status, or restore.")
    if not (STATE / "installer.iso").exists():
        installer(mirror)
    lxc(
        "init",
        NAME,
        "--empty",
        "--vm",
        "--no-profiles",
        "-s",
        "default",
        "-c",
        MARKER + "=" + owner(),
        "-c",
        "limits.cpu=4",
        "-c",
        "limits.memory=8GiB",
        "-d",
        "root,size=80GiB",
    )
    lxc("config", "device", "add", NAME, "eth0", "nic", "network=lxdbr0", "name=eth0")
    lxc(
        "config",
        "device",
        "add",
        NAME,
        "installer",
        "disk",
        "source=" + str(STATE / "installer.iso"),
        "boot.priority=10",
    )
    lxc("start", NAME)
    print("Installer started. Use canonical-vm-status or canonical-vm-console.")


def source_allowed(path: str) -> bool:
    return not any(
        part in {"tmp", ".git", ".direnv", ".worktrees", "node_modules", "__pycache__"}
        for part in Path(path).parts
    )


def source_archive() -> Path:
    files = (
        subprocess.check_output(
            ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
            cwd=ROOT,
        )
        .decode()
        .split("\0")
    )
    archive = STATE / "source.tar"
    with tarfile.open(archive, "w") as stream:
        for name in sorted(set(files)):
            if name and source_allowed(name) and (ROOT / name).exists():
                stream.add(ROOT / name, arcname=name, recursive=False)
    return archive


def guest(*args: str, **kwargs):
    checked_instance()
    return lxc("exec", NAME, "--", *args, **kwargs)


def wait_agent() -> None:
    checked_instance()
    deadline = time.monotonic() + 600
    while time.monotonic() < deadline:
        result = subprocess.run(
            [
                "lxc",
                "--force-local",
                "--project",
                "default",
                "exec",
                NAME,
                "--",
                "true",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if result.returncode == 0:
            return
        time.sleep(5)
    raise RuntimeError("Guest agent did not become ready within ten minutes.")


def snapshot(name: str) -> None:
    instance = checked_instance()
    if instance["status"] != "Stopped":
        raise RuntimeError("Stop the lab VM before taking a snapshot.")
    lxc("snapshot", NAME, name)


def stop() -> None:
    if checked_instance()["status"] == "Stopped":
        return
    guest("systemctl", "poweroff", "--no-block")
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        if checked_instance()["status"] == "Stopped":
            return
        time.sleep(5)
    raise RuntimeError("Guest shutdown did not finish within three minutes.")


def reboot() -> None:
    stop()
    lxc("start", NAME)
    wait_agent()


def guest_address() -> str:
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        state = query("/1.0/instances/" + NAME + "/state")
        for interface in (state.get("network") or {}).values():
            for address in interface.get("addresses", []):
                if address["family"] == "inet" and address["scope"] == "global":
                    return address["address"]
        time.sleep(2)
    raise RuntimeError("Guest did not receive an IPv4 address within two minutes.")


def ssh_command(*args: str) -> list[str]:
    checked_instance()
    actual_owner = output(
        "lxc",
        "--force-local",
        "--project",
        "default",
        "exec",
        NAME,
        "--",
        "cat",
        "/etc/canonical-lab",
    )
    if actual_owner != owner():
        raise RuntimeError("Guest marker does not match this lab.")
    address = guest_address()
    key = subprocess.check_output(
        [
            "lxc",
            "--force-local",
            "--project",
            "default",
            "exec",
            NAME,
            "--",
            "cat",
            "/etc/ssh/ssh_host_ed25519_key.pub",
        ],
        text=True,
    ).strip()
    known_hosts = STATE / "known_hosts"
    expected = NAME + " " + key + "\n"
    if known_hosts.exists() and known_hosts.read_text() != expected:
        raise RuntimeError("Guest SSH host key changed.")
    if not known_hosts.exists():
        private_file(known_hosts, expected)
    return [
        "ssh",
        "-F",
        "/dev/null",
        "-i",
        str(STATE / "secrets/ssh"),
        "-o",
        "IdentityAgent=none",
        "-o",
        "IdentitiesOnly=yes",
        "-o",
        "ForwardAgent=no",
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=15",
        "-o",
        "ServerAliveInterval=30",
        "-o",
        "ServerAliveCountMax=6",
        "-o",
        "StrictHostKeyChecking=yes",
        "-o",
        "HostKeyAlias=" + NAME,
        "-o",
        "UserKnownHostsFile=" + str(known_hosts),
        "canonical-test@" + address,
        shlex.join(args),
    ]


def remote(*args: str, desktop: bool = False, **kwargs):
    if desktop:
        args = (
            "systemd-run",
            "--user",
            "--wait",
            "--pipe",
            "--collect",
            "--expand-environment=no",
            *args,
        )
    return run(*ssh_command(*args), **kwargs)


def logs() -> None:
    checked_instance()
    directory = STATE / "reports" / time.strftime("%Y%m%d-%H%M%S")
    directory.mkdir(parents=True, mode=0o700)
    commands = {
        "system-journal": ["journalctl", "-b", "-p", "warning", "--no-pager"],
        "units": ["systemctl", "--failed", "--no-pager"],
        "storage": ["lsblk", "-f"],
        "desktop": ["journalctl", "-b", "_UID=1000", "--no-pager", "-n", "300"],
    }
    for name, args in commands.items():
        with (directory / (name + ".log")).open("w") as stream:
            guest(*args, stdout=stream, stderr=subprocess.STDOUT)
    print("Reports: " + str(directory))


def guest_stage(stage: str, desktop: bool = False) -> None:
    if desktop:
        wait_desktop()
    directory = STATE / "reports"
    directory.mkdir(exist_ok=True, mode=0o700)
    log = directory / (time.strftime("%Y%m%d-%H%M%S-") + stage + ".log")
    print("Running guest stage " + stage + "; log: " + str(log), flush=True)
    code = 1
    try:
        with log.open("w") as stream:
            remote(
                "bash",
                "/home/canonical-test/dotfiles/scripts/canonical-vm-guest.sh",
                stage,
                desktop=desktop,
                stdout=stream,
                stderr=subprocess.STDOUT,
                timeout=14400,
            )
        code = 0
    except subprocess.CalledProcessError as error:
        code = error.returncode
        raise
    finally:
        log.with_suffix(".json").write_text(
            json.dumps({"stage": stage, "exit_code": code}) + "\n"
        )


def wait_desktop() -> None:
    deadline = time.monotonic() + 180
    while time.monotonic() < deadline:
        try:
            remote(
                "sh",
                "-c",
                'test -n "$WAYLAND_DISPLAY" '
                '&& test "${XDG_CURRENT_DESKTOP#*GNOME}" != "$XDG_CURRENT_DESKTOP" '
                "&& /usr/bin/gnome-extensions list >/dev/null "
                '&& test ! -e "$XDG_RUNTIME_DIR/gnome-shell-disable-extensions"',
                desktop=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                timeout=20,
            )
            return
        except subprocess.CalledProcessError:
            time.sleep(5)
    raise RuntimeError("The GNOME user session is not ready.")


def sync_source() -> None:
    wait_agent()
    archive = source_archive()
    remote("mkdir", "-p", "/home/canonical-test/dotfiles")
    remote("test", "!", "-L", "/home/canonical-test/dotfiles")
    remote(
        "find",
        "/home/canonical-test/dotfiles",
        "-mindepth",
        "1",
        "-maxdepth",
        "1",
        "!",
        "-name",
        ".git",
        "-exec",
        "rm",
        "-rf",
        "--",
        "{}",
        "+",
    )
    with archive.open("rb") as stream:
        remote("tar", "-xf", "-", "-C", "/home/canonical-test/dotfiles", stdin=stream)


def configure_keyring() -> None:
    with (STATE / "secrets/login-password").open("rb") as stream:
        guest(
            "bash",
            "/home/canonical-test/dotfiles/scripts/canonical-vm-keyring.sh",
            stdin=stream,
        )


def deploy_guest() -> None:
    configure_keyring()
    reboot()
    guest_stage("setup", desktop=True)


def bootstrap() -> None:
    sync_source()
    signing_key = STATE / "secrets/signing.gpg"
    if signing_key.exists():
        with signing_key.open("rb") as stream:
            remote("gpg", "--batch", "--import", stdin=stream)
    guest_stage("identity")
    if not signing_key.exists():
        with signing_key.open("xb") as stream:
            signing_key.chmod(0o600)
            remote(
                "gpg",
                "--batch",
                "--export-secret-keys",
                "canonical-test@example.invalid",
                stdout=stream,
            )
    guest_stage("nix")
    stop()
    snapshot("nix-ready")
    lxc("start", NAME)
    wait_agent()
    deploy_guest()


def test_guest() -> None:
    wait_agent()
    wait_desktop()
    guest_stage("settings", desktop=True)
    reboot()
    wait_desktop()
    guest_stage("check", desktop=True)
    screenshot()
    reboot()
    wait_desktop()
    guest_stage("session", desktop=True)
    screenshot()
    logs()


def wait_install() -> None:
    deadline = time.monotonic() + 5400
    while time.monotonic() < deadline:
        if checked_instance()["status"] == "Stopped":
            return
        time.sleep(15)
    raise RuntimeError(
        "Installer has not stopped after 90 minutes. Inspect the guest console."
    )


def screenshot() -> None:
    for attempt in range(3):
        try:
            capture_screenshot()
            return
        except subprocess.CalledProcessError as error:
            if error.cmd[0] != "spicy-screenshot" or attempt == 2:
                raise
            print("SPICE capture failed; retrying in three seconds.", flush=True)
            time.sleep(3)


def capture_screenshot() -> None:
    checked_instance()
    client = shutil.which("lxc")
    if not client:
        raise RuntimeError("LXD client is missing.")
    directory = STATE / "reports"
    directory.mkdir(exist_ok=True, mode=0o700)
    target = directory / (time.strftime("%Y%m%d-%H%M%S") + ".ppm")
    env = {**os.environ, "PATH": "/nonexistent"}
    with subprocess.Popen(
        [
            client,
            "--force-local",
            "--project",
            "default",
            "console",
            NAME,
            "--type=vga",
        ],
        env=env,
        cwd=STATE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    ) as proxy:
        try:
            assert proxy.stdout
            deadline = time.monotonic() + 30
            data = b""
            while time.monotonic() < deadline:
                if select.select([proxy.stdout], [], [], 1)[0]:
                    data += os.read(proxy.stdout.fileno(), 4096)
                    match = re.search(rb"spice\+unix://[^\s]+", data)
                    if match:
                        run(
                            "spicy-screenshot",
                            "--uri=" + match[0].decode(),
                            "--out-file=" + str(target),
                            cwd=STATE,
                            env={
                                **os.environ,
                                "SPICE_DISABLE_CHANNELS": "playback-0,record-0",
                            },
                            timeout=60,
                        )
                        run("magick", str(target), str(target.with_suffix(".png")))
                        print(target.with_suffix(".png"))
                        return
                if proxy.poll() is not None:
                    break
            raise RuntimeError(
                "No guest SPICE socket returned: " + data.decode(errors="replace")
            )
        finally:
            proxy.terminate()
            try:
                proxy.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proxy.kill()
                proxy.wait()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=[
            "create",
            "status",
            "console",
            "start",
            "stop",
            "snapshot",
            "restore",
            "delete",
            "finish-install",
            "bootstrap",
            "test",
            "logs",
            "screenshot",
            "wait-install",
            "reboot",
            "deploy",
            "sync-source",
        ],
    )
    parser.add_argument(
        "snapshot", nargs="?", choices=["clean", "nix-ready", "working", "diagnostic"]
    )
    parser.add_argument("--mirror", default=RELEASE)
    args = parser.parse_args()
    if args.action == "create":
        if not args.mirror.startswith("https://"):
            parser.error("Use an HTTPS ISO mirror.")
        create(args.mirror)
        return
    instance = checked_instance()
    if args.action == "bootstrap":
        bootstrap()
    elif args.action == "sync-source":
        sync_source()
        guest_stage("identity")
    elif args.action == "wait-install":
        wait_install()
    elif args.action == "deploy":
        deploy_guest()
    elif args.action == "reboot":
        reboot()
    elif args.action == "stop":
        stop()
    elif args.action == "test":
        test_guest()
    elif args.action == "logs":
        logs()
    elif args.action == "screenshot":
        screenshot()
    elif args.action == "status":
        print(json.dumps(instance, indent=2))
    elif args.action == "console":
        lxc("console", NAME, "--type=vga", cwd=STATE)
    elif args.action == "snapshot":
        if not args.snapshot:
            parser.error("snapshot name required")
        snapshot(args.snapshot)
    elif args.action == "restore":
        if not args.snapshot:
            parser.error("snapshot name required")
        if instance["status"] != "Stopped":
            raise RuntimeError("Stop the lab VM before restore.")
        lxc("restore", NAME, args.snapshot)
    elif args.action == "finish-install":
        if instance["status"] != "Stopped":
            raise RuntimeError("Wait for the installer to power off.")
        lxc("config", "device", "remove", NAME, "installer")
        lxc("start", NAME)
        wait_agent()
        guest("test", "-f", "/etc/canonical-lab")
        stop()
        snapshot("clean")
    else:
        lxc(args.action, NAME)


if __name__ == "__main__":
    main()
