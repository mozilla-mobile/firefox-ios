/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const userScripts = {};

function includeOnce (userScript, initializer) {
    if (!userScripts[userScript]) {
      userScripts[userScript] = true;
      if (typeof initializer === 'function') {
        initializer();
      }
      return false;
    }

    return true;  
}

function ffi (key, value) {
  Object.defineProperty(__firefox__, key, {
    enumerable: false,
    configurable: false,
    writable: false, 
    value,
  });
}

module.exports = Object.freeze({
  includeOnce,
  ffi,
});

// this is our main entry point for FFI in a JS Context.
__firefox__ = {};

ffi("isConfigured", true);