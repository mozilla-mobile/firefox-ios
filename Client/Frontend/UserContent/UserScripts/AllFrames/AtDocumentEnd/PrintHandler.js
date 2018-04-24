/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("PrintHandler", function() {
  window.print = function() {
    webkit.messageHandlers.printHandler.postMessage({});
  };
});
