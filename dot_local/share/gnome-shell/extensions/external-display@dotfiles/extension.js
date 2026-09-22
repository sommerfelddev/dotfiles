import Meta from "gi://Meta";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";

export default class ExternalDisplay extends Extension {
  enable() {
    this._manager = global.backend.get_monitor_manager();
    this._signal = this._manager.connect("monitors-changed", () =>
      this._apply(),
    );
    this._apply();
  }

  _apply() {
    if (
      this._manager.has_builtin_panel &&
      this._manager.can_switch_config() &&
      this._manager.get_is_builtin_display_on()
    )
      this._manager.switch_config(Meta.MonitorSwitchConfigType.EXTERNAL);
  }

  disable() {
    this._manager.disconnect(this._signal);
    this._manager = null;
  }
}
