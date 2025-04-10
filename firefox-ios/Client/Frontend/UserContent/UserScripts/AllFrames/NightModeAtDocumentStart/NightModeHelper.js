/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import { setEnabled } from "./DarkReader.js";
Object.defineProperty(window.__firefox__, "NightMode", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: { enabled: false },
});

Object.defineProperty(window.__firefox__.NightMode, "setEnabled", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: setEnabled,
});

webkit.messageHandlers.NightMode.postMessage({ state: "ready" });
