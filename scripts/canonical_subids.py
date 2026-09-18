"""Assign missing local subordinate IDs without changing existing allocations."""

import argparse
import ctypes
import grp
import os
import pwd
import subprocess
import tempfile
from contextlib import contextmanager
from pathlib import Path


@contextmanager
def account_lock():
    libc = ctypes.CDLL(None, use_errno=True)
    if libc.lckpwdf() != 0:
        raise OSError("Cannot lock the account files; try again later.")
    try:
        yield
    finally:
        libc.ulckpwdf()


def allocation_policy(etc: Path) -> dict[str, int]:
    for line in (etc / "nsswitch.conf").read_text().splitlines():
        key, _, value = line.split("#", 1)[0].partition(":")
        if key.strip() == "subid" and value.split() != ["files"]:
            raise ValueError(
                "Subordinate IDs use an external provider; no files changed."
            )
    policy = {}
    for line in (etc / "login.defs").read_text().splitlines():
        fields = line.split("#", 1)[0].split()
        if fields and fields[0] in {
            f"SUB_{kind}_{limit}"
            for kind in ("UID", "GID")
            for limit in ("MIN", "MAX", "COUNT")
        }:
            key, value = fields
            policy[key] = int(value)
    return policy


def read_ranges(text: str) -> list[tuple[str, int, int]]:
    ranges = []
    for line in text.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        owner, first, size = line.split(":")
        start, count = int(first), int(size)
        if not owner or start < 0 or count <= 0 or start + count > 2**32 - 1:
            raise ValueError("Invalid subordinate ID range; no files changed.")
        ranges.append((owner, start, count))
    return ranges


def free_range(
    occupied: list[tuple[int, int]], minimum: int, maximum: int, count: int
) -> int:
    start = minimum
    for first, end in sorted(occupied):
        if start + count <= first:
            break
        start = max(start, end)
    if start + count - 1 > maximum:
        raise ValueError("No free subordinate ID range within login.defs limits.")
    return start


def allocation_limits(policy: dict[str, int], kind: str) -> tuple[int, int, int]:
    minimum = policy.get(f"SUB_{kind}_MIN", 100000)
    maximum = policy.get(f"SUB_{kind}_MAX", 600100000)
    count = policy.get(f"SUB_{kind}_COUNT", 65536)
    if count == 0:
        raise ValueError(f"Subordinate {kind} allocation is disabled in login.defs.")
    if not (0 < minimum <= maximum < 2**32 - 1) or count < 65536:
        raise ValueError(f"Invalid or insufficient SUB_{kind} limits in login.defs.")
    return minimum, maximum, count


def plan_allocations(
    etc: Path, name: str, uid: int, user_ids: set[int], group_ids: set[int]
) -> dict[Path, str]:
    policy = allocation_policy(etc)
    changes = {}
    for kind, used in (("UID", user_ids), ("GID", group_ids)):
        path = etc / f"sub{kind.lower()}"
        if path.is_symlink():
            raise ValueError(f"Refusing to replace symlink: {path}")
        text = path.read_text() if path.exists() else ""
        ranges = read_ranges(text)
        if any(owner in {name, str(uid)} for owner, _, _ in ranges):
            continue
        minimum, maximum, count = allocation_limits(policy, kind)
        occupied = [(first, first + size) for _, first, size in ranges]
        occupied.extend((number, number + 1) for number in used | {uid})
        start = free_range(occupied, minimum, maximum, count)
        separator = "\n" if text and not text.endswith("\n") else ""
        changes[path] = f"{text}{separator}{name}:{start}:{count}\n"
    return changes


def write_atomic(path: Path, text: str) -> None:
    info = path.stat() if path.exists() else None
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(text)
            stream.flush()
            if info:
                os.fchown(stream.fileno(), info.st_uid, info.st_gid)
            os.fchmod(stream.fileno(), (info.st_mode & 0o777) if info else 0o644)
            os.fsync(stream.fileno())
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def configure(name: str) -> None:
    account = pwd.getpwnam(name)
    if account.pw_uid == 0 or any(char in name for char in ":\n\r"):
        raise ValueError("Select a non-root login account.")
    with account_lock():
        changes = plan_allocations(
            Path("/etc"),
            name,
            account.pw_uid,
            {entry.pw_uid for entry in pwd.getpwall()},
            {entry.gr_gid for entry in grp.getgrall()} | {account.pw_gid},
        )
        for path, text in changes.items():
            write_atomic(path, text)
            print(f"Assigned a subordinate ID range in {path} for {name}.")
    for flags in ([], ["-g"]):
        subprocess.run(["/usr/bin/getsubids", *flags, name], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("user")
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise SystemExit(
            "Run this command through sudo with Ubuntu's /usr/bin/python3."
        )
    configure(args.user)


if __name__ == "__main__":
    main()
