/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("NativeEvent", function() {
  let _callbacks = {};

  class NativeEvent {
    constructor(securityToken, pipeId, name) {
      if (securityToken !== SECURITY_TOKEN) {
        Object.defineProperty(this, "pipeId", {
          configurable: false,
          writable: false,
          value: null
        });

        Object.defineProperty(this, "name", {
          configurable: false,
          writable: false,
          value: null
        });

        return;
      }

      Object.defineProperty(this, "pipeId", {
        configurable: false,
        writable: false,
        value: pipeId
      });

      Object.defineProperty(this, "name", {
        configurable: false,
        writable: false,
        value: name
      });
    }

    static dispatch(securityToken, pipeId, name, args) {
      if (securityToken !== SECURITY_TOKEN) {
        return;
      }
      let callbacks = _callbacks[pipeId + ":" + name];
      if (!callbacks) {
        return;
      }
      callbacks.forEach(callback => callback.apply(this, args));
    }

    addListener(callback) {
      let callbacks = _callbacks[this.pipeId + ":" + this.name];
      if (!callbacks) {
        callbacks = _callbacks[this.pipeId + ":" + this.name] = new Set();
      }
      callbacks.add(callback);
    }

    removeListener(callback) {
      let callbacks = _callbacks[this.pipeId + ":" + this.name];
      if (!callbacks) {
        return;
      }
      callbacks.delete(callback);
    }

    hasListener(callback) {
      let callbacks = _callbacks[this.pipeId + ":" + this.name];
      if (!callbacks) {
        return false;
      }
      return callbacks.has(callback);
    }
  }

  Object.defineProperty(window.__firefox__, "NativeEvent", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: NativeEvent
  });
});
