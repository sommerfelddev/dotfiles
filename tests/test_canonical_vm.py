import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "canonical_vm", ROOT / "scripts/canonical_vm.py"
)
assert SPEC and SPEC.loader
vm = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(vm)


class LabTests(unittest.TestCase):
    def test_reboot_checks_extensions_without_reapplying_settings(self):
        with (
            patch.object(vm, "wait_agent"),
            patch.object(vm, "wait_desktop"),
            patch.object(vm, "guest_stage") as stage,
            patch.object(vm, "reboot"),
            patch.object(vm, "remote"),
            patch.object(vm, "screenshot"),
            patch.object(vm, "logs"),
        ):
            vm.test_guest()
        self.assertEqual(stage.call_args.args, ("session",))

    def test_desktop_waits_for_extension_startup_check(self):
        with patch.object(vm, "remote") as remote:
            vm.wait_desktop()
        command = remote.call_args.args[2]
        self.assertIn("gnome-extensions list", command)
        self.assertIn(
            'test ! -e "$XDG_RUNTIME_DIR/gnome-shell-disable-extensions"', command
        )

    def test_screenshot_retries_a_failed_spice_connection(self):
        error = subprocess.CalledProcessError(1, ["spicy-screenshot"])
        with (
            patch.object(
                vm, "capture_screenshot", side_effect=[error, None]
            ) as capture,
            patch.object(vm.time, "sleep"),
        ):
            vm.screenshot()
        self.assertEqual(capture.call_count, 2)

    def test_screenshot_retry_is_bounded(self):
        error = subprocess.CalledProcessError(1, ["spicy-screenshot"])
        with (
            patch.object(vm, "capture_screenshot", side_effect=error) as capture,
            patch.object(vm.time, "sleep"),
            self.assertRaises(subprocess.CalledProcessError),
        ):
            vm.screenshot()
        self.assertEqual(capture.call_count, 3)

    def test_deploy_prepares_keyring_before_desktop_setup(self):
        calls = []
        with (
            patch.object(
                vm, "configure_keyring", side_effect=lambda: calls.append("keyring")
            ),
            patch.object(vm, "reboot", side_effect=lambda: calls.append("reboot")),
            patch.object(
                vm, "guest_stage", side_effect=lambda *a, **k: calls.append("setup")
            ),
        ):
            vm.deploy_guest()
        self.assertEqual(calls, ["keyring", "reboot", "setup"])

    def test_keyring_password_is_sent_on_stdin(self):
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory)
            (state / "secrets").mkdir()
            (state / "secrets/login-password").write_bytes(b"test-password")
            with (
                patch.object(vm, "STATE", state),
                patch.object(vm, "guest") as guest,
            ):
                guest.side_effect = lambda *args, **kwargs: self.assertEqual(
                    kwargs["stdin"].read(), b"test-password"
                )
                vm.configure_keyring()
            self.assertNotIn("test-password", str(guest.call_args.args))

    def test_address_waits_for_dhcp(self):
        ready = {
            "network": {
                "enp5s0": {
                    "addresses": [
                        {"family": "inet", "scope": "global", "address": "192.0.2.10"}
                    ]
                }
            }
        }
        with (
            patch.object(vm, "query", side_effect=[{"network": {}}, ready]),
            patch.object(vm.time, "sleep") as sleep,
        ):
            self.assertEqual(vm.guest_address(), "192.0.2.10")
        sleep.assert_called_once()

    def test_stop_uses_guest_shutdown_instead_of_power_button(self):
        with (
            patch.object(
                vm,
                "checked_instance",
                side_effect=[{"status": "Running"}, {"status": "Stopped"}],
            ),
            patch.object(vm, "guest") as guest,
            patch.object(vm, "lxc") as lxc,
        ):
            vm.stop()
        guest.assert_called_once_with("systemctl", "poweroff", "--no-block")
        lxc.assert_not_called()

    def test_desktop_commands_preserve_shell_expansion(self):
        with (
            patch.object(vm, "ssh_command", side_effect=lambda *args: ["ssh", *args]),
            patch.object(vm, "run") as command,
        ):
            vm.remote("sh", "-c", 'test -n "$WAYLAND_DISPLAY"', desktop=True)
        self.assertIn("--expand-environment=no", command.call_args.args)

    def test_source_checks_exclude_lab_data(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            (base / "tmp").mkdir()
            (base / "tmp/generated.py").touch()
            (base / "source.py").touch()
            result = subprocess.check_output(
                [
                    "bash",
                    "-c",
                    'source "$1"; _find_by_ext py',
                    "bash",
                    str(ROOT / "just-lib.sh"),
                ],
                cwd=base,
                text=True,
            )
            self.assertEqual(result.strip(), "./source.py")

    def test_ownership_requires_vm_and_matching_marker(self):
        good = {"type": "virtual-machine", "config": {vm.MARKER: "test-id"}}
        vm.require_owned(good, "test-id")
        for bad in [{}, {**good, "type": "container"}, {**good, "config": {}}]:
            with self.assertRaises(RuntimeError):
                vm.require_owned(bad, "test-id")

    def test_source_filter_excludes_secrets_and_host_git(self):
        for path in ["tmp/key", ".git/config", ".direnv/env", "x/__pycache__/x.pyc"]:
            self.assertFalse(vm.source_allowed(path))
        self.assertTrue(vm.source_allowed("dot_config/git/config.tmpl"))
        self.assertTrue(vm.source_allowed("scripts/canonical_vm.py"))

    def test_autoinstall_targets_only_lab_disk(self):
        config = vm.autoinstall("hash", "ssh-ed25519 test", "disk-secret")
        install = config["autoinstall"]
        self.assertEqual(install["storage"]["layout"]["match"], {"path": "/dev/sda"})
        self.assertEqual(install["storage"]["layout"]["name"], "lvm")
        self.assertFalse(install["ssh"]["allow-pw"])
        self.assertNotIn("landscape", str(config))
        self.assertNotIn("interactive-sections", install)
        self.assertEqual(
            install["early-commands"][0], ["systemd-detect-virt", "--vm", "--quiet"]
        )

    def test_installer_boot_patch_requires_kernel(self):
        result = vm.boot_config("set timeout=30\n linux /casper/vmlinuz quiet ---\n")
        self.assertIn("autoinstall", result)
        self.assertIn("set timeout=1", result)
        with self.assertRaises(RuntimeError):
            vm.boot_config("unknown installer")

    def test_snapshot_rejects_running_vm(self):
        with (
            patch.object(vm, "checked_instance", return_value={"status": "Running"}),
            patch.object(vm, "lxc") as command,
        ):
            with self.assertRaises(RuntimeError):
                vm.snapshot("clean")
            command.assert_not_called()

    def test_ssh_does_not_use_host_config_or_agent(self):
        state = {
            "network": {
                "enp5s0": {
                    "addresses": [
                        {"address": "192.0.2.10", "family": "inet", "scope": "global"}
                    ]
                }
            }
        }
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.object(vm, "STATE", Path(directory)),
            patch.object(vm, "checked_instance"),
            patch.object(vm, "owner", return_value="test-id"),
            patch.object(vm, "output", return_value="test-id"),
            patch.object(vm, "query", return_value=state),
            patch.object(
                vm.subprocess, "check_output", return_value="ssh-ed25519 example"
            ),
        ):
            command = vm.ssh_command("true")
            self.assertEqual(command[:3], ["ssh", "-F", "/dev/null"])
            for option in [
                "IdentityAgent=none",
                "ForwardAgent=no",
                "StrictHostKeyChecking=yes",
                "IdentitiesOnly=yes",
            ]:
                self.assertIn(option, command)
            (Path(directory) / "known_hosts").write_text("changed")
            with self.assertRaises(RuntimeError):
                vm.ssh_command("true")

    def test_private_file_does_not_replace_existing_secret(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "secret"
            vm.private_file(path, "first")
            with self.assertRaises(FileExistsError):
                vm.private_file(path, "second")
            self.assertEqual(path.read_text(), "first")
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
