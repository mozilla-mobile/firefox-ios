/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {

"use strict";

var MAX_RADIUS = 10;

var longPressTimeout;
var touchDownX;
var touchDownY;

function cancel() {
  if (longPressTimeout) {
    clearTimeout(longPressTimeout);
    longPressTimeout = null;
  }
}

addEventListener("touchstart", function (event) {
  // Don't show the context menu for multi-touch events.
  if (event.touches.length !== 1) {
    cancel();
    return;
  }

  var data = {};
  var element = event.target;

  do {
    if (!data.link && element.localName === "a") {
      data.link = element.href;
    }
    if (!data.image && element.localName === "img") {
      data.image = element.src;
    }
    element = element.parentElement;
  } while (element);

  if (data.link || data.image) {
    var touch = event.touches[0];
    touchDownX = touch.screenX;
    touchDownY = touch.screenY;

    longPressTimeout = setTimeout(function () {
      cancel();
      webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);
    }, 500);
  }
});

addEventListener("touchmove", function (event) {
  if (longPressTimeout) {
    var { screenX, screenY } = event.touches[0];

    // Cancel the context menu if finger has moved beyond the maximum allowed distance.
    if (Math.abs(touchDownX - screenX) > MAX_RADIUS || Math.abs(touchDownY - screenY) > MAX_RADIUS) {
      cancel();
    }
  }
});

addEventListener("scroll", cancel);
addEventListener("touchend", cancel);

}) ();
