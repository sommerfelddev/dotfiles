import Clutter from "gi://Clutter";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import St from "gi://St";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";
import * as Main from "resource:///org/gnome/shell/ui/main.js";
import * as PanelMenu from "resource:///org/gnome/shell/ui/panelMenu.js";
import * as PopupMenu from "resource:///org/gnome/shell/ui/popupMenu.js";

export default class CorporatePanel extends Extension {
  enable() {
    this._cancellable = new Gio.Cancellable();
    this._button = new PanelMenu.Button(0.0, "Corporate status");
    const box = new St.BoxLayout({ style_class: "corporate-panel" });
    this._labels = {};
    for (const name of ["displays", "updates", "failed", "reboot"]) {
      const label = new St.Label({
        text: "",
        y_align: Clutter.ActorAlign.CENTER,
      });
      this._labels[name] = label;
      box.add_child(label);
    }
    this._button.add_child(box);
    this._addActions();
    Main.panel.addToStatusArea(this.uuid, this._button, 1, "right");
    this._refresh();
    this._timer = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 60, () => {
      this._refresh();
      return GLib.SOURCE_CONTINUE;
    });
  }

  _command(...args) {
    return [
      "/usr/bin/python3",
      GLib.build_filenamev([
        GLib.get_home_dir(),
        ".local/lib/dotfiles/canonical_panel.py",
      ]),
      ...args,
    ];
  }

  _addActions() {
    this._status = new PopupMenu.PopupMenuItem("Reading status...", {
      reactive: false,
    });
    this._button.menu.addMenuItem(this._status);
    for (const [name, title] of [
      ["monitor", "System monitor"],
      ["audio", "Audio mixer"],
      ["displays", "Display settings"],
      ["failed", "Failed services"],
      ["updates", "Available updates (apt and Snap)"],
      ["update", "Run dotfiles update"],
      ["reboot", "Reboot requirement details"],
      ["mail", "Thunderbird"],
    ]) {
      this._button.menu.addAction(title, () => {
        try {
          Gio.Subprocess.new(
            this._command("action", name),
            Gio.SubprocessFlags.NONE,
          );
        } catch (error) {
          Main.notifyError("Corporate panel", error.message);
        }
      });
    }
    this._button.menu.addAction("Refresh status", () => this._refresh());
  }

  _refresh() {
    if (this._process) return;
    const token = this._cancellable;
    try {
      const process = Gio.Subprocess.new(
        this._command("status"),
        Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE,
      );
      this._process = process;
      process.communicate_utf8_async(null, token, (source, result) => {
        if (token.is_cancelled()) return;
        this._process = null;
        try {
          const [, stdout, stderr] = source.communicate_utf8_finish(result);
          if (!source.get_successful())
            throw new Error(stderr || "Status command failed");
          this._render(JSON.parse(stdout));
        } catch (error) {
          this._showError(error);
        }
      });
    } catch (error) {
      this._showError(error);
    }
  }

  _render(status) {
    for (const [name, label] of Object.entries(this._labels)) {
      const value = status[name];
      label.set_text(value);
      label.visible = Boolean(value);
      const warning =
        value.includes("?") || (name === "updates" && value !== "APT 0");
      const critical =
        name === "reboot" || (name === "failed" && value !== "FAIL 0");
      label.set_style_class_name(
        critical
          ? "corporate-critical"
          : warning
            ? "corporate-warning"
            : "corporate-ok",
      );
    }
    this._status.label.set_text(
      status.errors
        ? "Some checks failed; see journal"
        : "APT uses the local package cache",
    );
    if (status.errors) console.warn(`Corporate panel: ${status.errors}`);
  }

  _showError(error) {
    this._render({
      displays: "EXT ?",
      updates: "APT ?",
      failed: "FAIL ?",
      reboot: "",
      errors: error.message,
    });
  }

  disable() {
    this._cancellable?.cancel();
    if (this._timer) GLib.Source.remove(this._timer);
    this._timer = null;
    this._process?.force_exit();
    this._process = null;
    this._button?.destroy();
    this._button = null;
    this._labels = null;
  }
}
