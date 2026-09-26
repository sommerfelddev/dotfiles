import assert from "node:assert/strict";

const bindings = new Map();
const Extension = class {
  getSettings() {
    return {};
  }
};
const Meta = { KeyBindingFlags: { NONE: 0 } };
const Shell = { ActionMode: { NORMAL: 1, OVERVIEW: 2 } };
const Main = {
  wm: {
    addKeybinding(name, settings, flags, mode, callback) {
      assert.equal(mode, 3);
      bindings.set(name, callback);
    },
    removeKeybinding(name) {
      bindings.delete(name);
    },
  },
};
let active = 0;
let activations = 0;
global.workspace_manager = {
  n_workspaces: 3,
  get_active_workspace_index: () => active,
  get_workspace_by_index: (index) => ({
    activate(time) {
      assert.equal(time, 123);
      active = index;
      activations++;
    },
  }),
};
global.get_current_time = () => 123;

// EXTENSION

const extension = new WorkspaceCycle();
extension.enable();
bindings.get("previous-workspace")();
assert.equal(active, 2);
bindings.get("next-workspace")();
assert.equal(active, 0);
bindings.get("next-workspace")();
assert.equal(active, 1);
global.workspace_manager.n_workspaces = 1;
extension.cycle(1);
assert.equal(activations, 3);
extension.disable();
assert.equal(bindings.size, 0);
extension.enable();
assert.equal(bindings.size, 2);
extension.disable();
