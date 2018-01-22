/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

if (window.__firefox__) {
  return;
}

Object.defineProperty(window, "__firefox__", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: {
    userScripts: {},
    includeOnce: function(userScript) {
      if (!__firefox__.userScripts[userScript]) {
        __firefox__.userScripts[userScript] = true;
        return false;
      }

      return true;
    }
  }
});

})();
