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
  value: async (enabled) => {
    const nightMode = await import("./DarkReader.js");
    nightMode.setEnabled(enabled);
  },
});

// const style = document.createElement("style");
// style.innerHTML = `body { background-color: green !important; }`;
// document.head.appendChild(style);

setEnabled(true);
webkit.messageHandlers.NightMode.postMessage({ state: "ready" });
