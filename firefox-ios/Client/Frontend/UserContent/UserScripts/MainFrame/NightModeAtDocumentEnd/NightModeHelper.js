/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
  value: async (enabled, shouldUseDarkReader = false) => {
    // NOTE: We intend to do a phased rollout, hence why we are using a flag here
    // to load DarkReader only for users who have opted in. Once we have rolled out to all users
    // the flag `shouldUseDarkReader` and LegacyNightModeHelper.js can be removed.
    const nightMode = shouldUseDarkReader
      ? await import("./DarkReader.js")
      : await import("./LegacyNightModeHelper.js");
    nightMode.setEnabled(enabled);
  },
});

window.addEventListener("pageshow", () => {
  webkit.messageHandlers.NightMode.postMessage({ state: "ready" });
});
