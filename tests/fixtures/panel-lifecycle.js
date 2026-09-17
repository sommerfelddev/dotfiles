import assert from "node:assert/strict";

const callbacks = [];
let killed = 0;
let removed = 0;
class Actor {
  constructor(props = {}) {
    Object.assign(this, props);
  }
  add_child() {}
  set_text(text) {
    this.text = text;
  }
  set_style_class_name(name) {
    this.style = name;
  }
  destroy() {
    this.destroyed = true;
  }
}
class Button extends Actor {
  menu = { addMenuItem() {}, addAction() {} };
}
class Item {
  label = new Actor();
}
class Extension {
  uuid = "test";
}
const St = { BoxLayout: Actor, Label: Actor };
const Clutter = { ActorAlign: { CENTER: 0 } };
const PanelMenu = { Button };
const PopupMenu = { PopupMenuItem: Item };
const Main = { panel: { addToStatusArea() {} }, notifyError() {} };
const GLib = {
  PRIORITY_DEFAULT: 0,
  SOURCE_CONTINUE: true,
  timeout_add_seconds: () => 1,
  Source: {
    remove() {
      removed++;
    },
  },
  get_home_dir: () => "/home/test",
  build_filenamev: (parts) => parts.join("/"),
};
const Gio = {
  Cancellable: class {
    cancelled = false;
    cancel() {
      this.cancelled = true;
    }
    is_cancelled() {
      return this.cancelled;
    }
  },
  SubprocessFlags: { NONE: 0, STDOUT_PIPE: 1, STDERR_PIPE: 2 },
  Subprocess: {
    new() {
      return {
        communicate_utf8_async(_input, _token, callback) {
          callbacks.push(callback);
        },
        force_exit() {
          killed++;
        },
      };
    },
  },
};

// EXTENSION

const panel = new CorporatePanel();
panel.enable();
panel._refresh();
assert.equal(callbacks.length, 1, "Do not overlap status processes");
panel._render({
  displays: "EXT 1",
  updates: "APT 3",
  failed: "FAIL 1",
  reboot: "",
  errors: "",
});
assert.equal(panel._labels.failed.style, "corporate-critical");
assert.equal(panel._labels.updates.style, "corporate-warning");
assert.equal(panel._labels.reboot.visible, false);
const button = panel._button;
panel.disable();
assert.equal(killed, 1);
assert.equal(removed, 1);
assert.equal(button.destroyed, true);
panel.enable();
callbacks[0]({}, {});
assert.ok(panel._process, "Old callbacks cannot clear the new process");
const data = {
  displays: "EXT 0",
  updates: "APT 0",
  failed: "FAIL 0",
  reboot: "REBOOT",
  errors: "",
};
callbacks[1](
  {
    communicate_utf8_finish: () => [true, JSON.stringify(data), ""],
    get_successful: () => true,
  },
  {},
);
assert.equal(panel._labels.reboot.visible, true);
assert.equal(panel._process, null);
panel.disable();
