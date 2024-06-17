/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

// Ensure this module only gets included once. This is
// required for user scripts injected into all frames.
window.__firefox__.includeOnce("ContextMenu", function() {
  function sendMessage(evt) {
    var target = evt.target;

    var targetLink = target.closest("a");
    var targetImage = target.closest("img");

    if (!targetLink && !targetImage) {
      return;
    }

    var data = {};

    const triggeringEvent = evt.changedTouches?.[0] ?? evt;
    data.touchX = triggeringEvent.pageX - window.scrollX;
    data.touchY = triggeringEvent.pageY - window.scrollY;

    if (targetLink) {
      data.link = targetLink.href;
      data.title = targetLink.textContent;
    }

    if (targetImage) {
      data.image = targetImage.src;
      data.title = data.title || targetImage.title;
      data.alt = targetImage.alt;
    }

    if (data.link || data.image) {
      webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);
    }
  }

  window.addEventListener("touchstart", sendMessage, true);
  window.addEventListener("mousedown", sendMessage, true);
});
