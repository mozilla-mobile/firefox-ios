// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Mirrors FrameworkDetector in desktop's ReportBrokenSiteChild.sys.mjs.
function getPageContext() {
  "use strict";

  function safe(read) {
    try {
      return read();
    } catch (_) {
      return undefined;
    }
  }

  function hasFastClick(win) {
    if (win.FastClick) {
      return true;
    }
    for (const property in win) {
      try {
        const proto = win[property].prototype;
        if (proto && proto.needsClick) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  return {
    languages: safe(() => Array.from(navigator.languages || [])),
    userAgent: safe(() => navigator.userAgent),
    fastclick: safe(() => hasFastClick(window)),
    marfeel: safe(() => !!window.marfeel),
    mobify: safe(() => !!window.Mobify?.Tag)
  };
}

// This bundle runs in the page content world, which has no `window.__firefox__`.
Object.defineProperty(window, "__firefoxWebCompat__", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({ getPageContext })
});
