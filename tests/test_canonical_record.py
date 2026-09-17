import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "record", ROOT / "dot_local/lib/dotfiles/record.py"
)
assert SPEC and SPEC.loader
record = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(record)


class RecorderTests(unittest.TestCase):
    def test_start_is_idempotent(self):
        with (
            patch.object(record, "active", return_value=True),
            patch.object(record.subprocess, "run") as run,
        ):
            record.start(Path("/unused"))
        run.assert_not_called()

    def test_stop_before_portal_selection_stops_only_owned_service(self):
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.object(record, "active", return_value=True),
            patch.object(record.subprocess, "run") as run,
        ):
            record.stop(Path(directory))
        run.assert_called_once_with(
            ["systemctl", "--user", "stop", "dotfiles-record.service"], check=True
        )

    def test_stop_uses_recorder_ipc_when_available(self):
        with tempfile.TemporaryDirectory() as directory:
            runtime = Path(directory)
            (runtime / "control.sock").touch()
            with (
                patch.object(record, "active", return_value=True),
                patch.object(record.subprocess, "run") as run,
            ):
                record.stop(runtime)
            command = run.call_args.args[0]
        self.assertIn("--command=gsr-cli", command)
        self.assertEqual(command[-1], "stop")


if __name__ == "__main__":
    unittest.main()
