import assert from 'node:assert/strict';

class Extension {}
const Meta = {MonitorSwitchConfigType: {EXTERNAL: 2}};
let callback;
let requests = 0;
let switchable = true;
let builtinOn = true;
const manager = {
    has_builtin_panel: true,
    connect(signal, handler) {
        assert.equal(signal, 'monitors-changed');
        callback = handler;
        return 1;
    },
    disconnect(id) {
        assert.equal(id, 1);
        callback = null;
    },
    can_switch_config: () => switchable,
    get_is_builtin_display_on: () => builtinOn,
    switch_config(type) {
        assert.equal(type, Meta.MonitorSwitchConfigType.EXTERNAL);
        requests++;
        builtinOn = false;
    },
};
globalThis.global = {backend: {get_monitor_manager: () => manager}};

// EXTENSION

const extension = new ExternalDisplay();
extension.enable();
assert.equal(requests, 1);
callback();
assert.equal(requests, 1);

// One connected display, or a closed lid, prevents switching.
switchable = false;
builtinOn = true;
callback();
assert.equal(requests, 1);
switchable = true;
callback();
assert.equal(requests, 2);

manager.has_builtin_panel = false;
builtinOn = true;
callback();
assert.equal(requests, 2);
extension.disable();
assert.equal(callback, null);
manager.has_builtin_panel = true;
extension.enable();
assert.equal(requests, 3);
extension.disable();
