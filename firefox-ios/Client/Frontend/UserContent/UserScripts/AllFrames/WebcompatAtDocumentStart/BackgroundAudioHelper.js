// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// Captures the native visibilitychange listener slot at document start,
// before any page scripts. When background audio is active, Swift signals
// via __firefoxBlockVisibilityChange and this early listener prevents
// page scripts from seeing the event and pausing media.

const nativeHiddenDescriptor = Object.getOwnPropertyDescriptor(Document.prototype, 'hidden');

document.addEventListener('visibilitychange', (e) => {
  const reallyHidden = nativeHiddenDescriptor.get.call(document);
  if (window.__firefoxBlockVisibilityChange && reallyHidden) {
    e.stopImmediatePropagation();
  }
}, true);
