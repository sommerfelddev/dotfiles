import tempfile
import unittest
from contextlib import nullcontext
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from scripts import canonical_subids as subids


class SubidTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.etc = Path(self.directory.name)
        for name, text in {
            "nsswitch.conf": "passwd: files authd\ngroup: files authd\n",
            "login.defs": "SUB_UID_MIN 1000000\nSUB_GID_MIN 1000000\n",
            "subuid": "ruifm:1000000:65536\n",
            "subgid": "ruifm:1000000:65536\n",
        }.items():
            (self.etc / name).write_text(text)
        self.uid = 10000
        self.name = "rui.marques@canonical.com"

    def plan(self):
        return subids.plan_allocations(self.etc, self.name, self.uid, {10000}, {10000})

    def test_allocates_after_existing_ranges(self):
        changes = self.plan()
        for name in ("subuid", "subgid"):
            self.assertEqual(
                changes[self.etc / name],
                f"ruifm:1000000:65536\n{self.name}:1065536:65536\n",
            )

    def test_preserves_existing_name_and_numeric_allocations(self):
        (self.etc / "subuid").write_text(f"{self.name}:2000000:1000\n")
        (self.etc / "subgid").write_text(f"{self.uid}:3000000:65536\n")
        self.assertEqual(self.plan(), {})

    def test_fills_only_missing_file_and_is_idempotent(self):
        (self.etc / "subgid").write_text(f"{self.name}:2000000:65536\n")
        changes = self.plan()
        self.assertEqual(list(changes), [self.etc / "subuid"])
        for path, text in changes.items():
            subids.write_atomic(path, text)
        self.assertEqual(self.plan(), {})

    def test_skips_real_user_and_group_ids(self):
        changes = subids.plan_allocations(
            self.etc, self.name, self.uid, {1065536}, {1065537}
        )
        self.assertIn(f"{self.name}:1065537:65536", changes[self.etc / "subuid"])
        self.assertIn(f"{self.name}:1065538:65536", changes[self.etc / "subgid"])

    def test_rejects_external_provider(self):
        (self.etc / "nsswitch.conf").write_text("subid: sss\n")
        with self.assertRaisesRegex(ValueError, "provider"):
            self.plan()

    def test_rejects_exhausted_range(self):
        with (self.etc / "login.defs").open("a") as stream:
            stream.write("SUB_UID_MAX 1065535\n")
        with self.assertRaisesRegex(ValueError, "free"):
            self.plan()

    def test_rejects_disabled_allocation(self):
        with (self.etc / "login.defs").open("a") as stream:
            stream.write("SUB_UID_COUNT 0\n")
        with self.assertRaisesRegex(ValueError, "disabled"):
            self.plan()

    def test_rejects_malformed_ranges_before_writing(self):
        (self.etc / "subgid").write_text("broken entry\n")
        with self.assertRaises(ValueError):
            self.plan()
        self.assertEqual((self.etc / "subuid").read_text(), "ruifm:1000000:65536\n")

    def test_handles_missing_file_and_missing_final_newline(self):
        (self.etc / "subuid").unlink()
        (self.etc / "subgid").write_text("ruifm:1000000:65536")
        changes = self.plan()
        self.assertEqual(changes[self.etc / "subuid"], f"{self.name}:1000000:65536\n")
        self.assertIn("65536\n" + self.name, changes[self.etc / "subgid"])

    def test_atomic_write_preserves_mode_and_leaves_no_temporary_file(self):
        target = self.etc / "subuid"
        target.chmod(0o640)
        subids.write_atomic(target, "replacement\n")
        self.assertEqual(target.read_text(), "replacement\n")
        self.assertEqual(target.stat().st_mode & 0o777, 0o640)
        self.assertEqual(len(list(self.etc.iterdir())), 4)

    def test_failed_replace_preserves_file(self):
        target = self.etc / "subuid"
        with (
            patch.object(subids.os, "replace", side_effect=OSError("failure")),
            self.assertRaises(OSError),
        ):
            subids.write_atomic(target, "replacement\n")
        self.assertEqual(target.read_text(), "ruifm:1000000:65536\n")
        self.assertEqual(len(list(self.etc.iterdir())), 4)

    def test_rejects_symlink_without_touching_its_target(self):
        path = self.etc / "subuid"
        path.unlink()
        path.symlink_to(self.etc / "subgid")
        with self.assertRaisesRegex(ValueError, "symlink"):
            self.plan()
        self.assertEqual((self.etc / "subgid").read_text(), "ruifm:1000000:65536\n")

    def test_respects_larger_configured_range_count(self):
        with (self.etc / "login.defs").open("a") as stream:
            stream.write("SUB_UID_COUNT 131072\n")
        self.assertIn(f"{self.name}:1065536:131072", self.plan()[self.etc / "subuid"])

    def test_lock_is_released_on_error(self):
        libc = MagicMock()
        libc.lckpwdf.return_value = 0
        with (
            patch.object(subids.ctypes, "CDLL", return_value=libc),
            self.assertRaises(ValueError),
            subids.account_lock(),
        ):
            raise ValueError("failure")
        libc.ulckpwdf.assert_called_once_with()

    def test_failed_lock_does_not_enter_or_unlock(self):
        libc = MagicMock()
        libc.lckpwdf.return_value = -1
        with (
            patch.object(subids.ctypes, "CDLL", return_value=libc),
            self.assertRaises(OSError),
            subids.account_lock(),
        ):
            self.fail("Entered without the account lock")
        libc.ulckpwdf.assert_not_called()

    def test_configure_verifies_both_ranges_with_system_commands(self):
        with (
            patch.object(
                subids.pwd,
                "getpwnam",
                return_value=SimpleNamespace(pw_uid=10000, pw_gid=10000),
            ),
            patch.object(subids.pwd, "getpwall", return_value=[]),
            patch.object(subids.grp, "getgrall", return_value=[]),
            patch.object(subids, "account_lock", return_value=nullcontext()),
            patch.object(subids, "plan_allocations", return_value={}) as plan,
            patch.object(subids, "write_atomic") as write,
            patch.object(subids.subprocess, "run") as run,
        ):
            subids.configure(self.name)
        plan.assert_called_once_with(Path("/etc"), self.name, 10000, set(), {10000})
        write.assert_not_called()
        self.assertEqual(run.call_count, 2)
        run.assert_any_call(["/usr/bin/getsubids", self.name], check=True)
        run.assert_any_call(["/usr/bin/getsubids", "-g", self.name], check=True)

    def test_root_account_is_rejected_before_file_access(self):
        with (
            patch.object(
                subids.pwd, "getpwnam", return_value=SimpleNamespace(pw_uid=0)
            ),
            patch.object(subids, "account_lock") as lock,
            self.assertRaises(ValueError),
        ):
            subids.configure("root")
        lock.assert_not_called()


if __name__ == "__main__":
    unittest.main()
