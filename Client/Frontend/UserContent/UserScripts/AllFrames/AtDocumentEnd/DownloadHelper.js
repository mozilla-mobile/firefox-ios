/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

Object.defineProperty(window.__firefox__, "download", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: function(url, securityToken) {
    if (securityToken !== SECURITY_TOKEN) {
      return;
    }

    var link = document.createElement("a");
    link.href = url;
    link.dispatchEvent(new MouseEvent("click"));
  }
});
