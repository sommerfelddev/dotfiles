import Meta from "gi://Meta";
import Shell from "gi://Shell";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";
import * as Main from "resource:///org/gnome/shell/ui/main.js";

export default class WorkspaceCycle extends Extension {
  enable() {
    const settings = this.getSettings();
    for (const [name, step] of [
      ["next-workspace", 1],
      ["previous-workspace", -1],
    ]) {
      Main.wm.addKeybinding(
        name,
        settings,
        Meta.KeyBindingFlags.NONE,
        Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
        () => this.cycle(step),
      );
    }
  }

  cycle(step) {
    const manager = global.workspace_manager;
    const count = manager.n_workspaces;
    if (count < 2) return;
    const index = (manager.get_active_workspace_index() + step + count) % count;
    manager.get_workspace_by_index(index).activate(global.get_current_time());
  }

  disable() {
    Main.wm.removeKeybinding("next-workspace");
    Main.wm.removeKeybinding("previous-workspace");
  }
}
