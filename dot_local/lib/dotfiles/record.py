"""Control one GNOME portal recording in a transient user service."""

import fcntl
import os
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path

APP = "com.dec05eba.gpu_screen_recorder"
UNIT = "dotfiles-record.service"


def active() -> bool:
    return (
        subprocess.run(
            ["systemctl", "--user", "is-active", "--quiet", UNIT],
            check=False,
        ).returncode
        == 0
    )


def start(runtime: Path) -> None:
    if active():
        return
    (runtime / "control.sock").unlink(missing_ok=True)
    videos = Path.home() / "vids"
    videos.mkdir(exist_ok=True)
    output = videos / (datetime.now(UTC).strftime("%Y-%m-%d_%H-%M-%S-%fZ") + ".mkv")
    subprocess.run(
        [
            "systemd-run",
            "--user",
            "--collect",
            "--unit=" + UNIT,
            "--property=KillSignal=SIGINT",
            "--property=TimeoutStopSec=30s",
            "/usr/bin/flatpak",
            "run",
            "--filesystem=" + str(videos),
            "--filesystem=" + str(runtime),
            "--command=gpu-screen-recorder",
            APP,
            "-w",
            "portal",
            "-f",
            "60",
            "-o",
            str(output),
            "-ipc",
            str(runtime / "control.sock"),
        ],
        check=True,
    )


def stop(runtime: Path) -> None:
    if not active():
        return
    if (runtime / "control.sock").exists():
        subprocess.run(
            [
                "/usr/bin/flatpak",
                "run",
                "--filesystem=" + str(runtime),
                "--command=gsr-cli",
                APP,
                "-ipc",
                str(runtime / "control.sock"),
                "stop",
            ],
            check=True,
        )
    else:
        subprocess.run(["systemctl", "--user", "stop", UNIT], check=True)


def main() -> None:
    action = sys.argv[1] if len(sys.argv) == 2 else "toggle"
    if action not in {"start", "stop", "toggle", "status"}:
        raise SystemExit("Use record start|stop|toggle|status")
    if action == "status":
        print("recording" if active() else "stopped")
        return
    runtime = Path(os.environ["XDG_RUNTIME_DIR"]) / "dotfiles-record"
    runtime.mkdir(mode=0o700, exist_ok=True)
    with (runtime / "lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if action == "stop" or (action == "toggle" and active()):
            stop(runtime)
        else:
            start(runtime)


if __name__ == "__main__":
    main()
