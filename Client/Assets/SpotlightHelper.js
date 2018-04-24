/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

var selectors = {
  title: "title",
  description: "meta[name='description'], body p",
};

function collectText(selector) {
  var el = document.querySelector(selector);
  return el ? el.getAttribute("content") || el.innerText || "" : "";
}

function assemblePayload(selectors) {
  var payload = {};
  for (var key in selectors) {
    payload[key] = collectText(selectors[key]);
  }
  return payload;
}

window.addEventListener("load", function() {
  var payload = assemblePayload(selectors);
  webkit.messageHandlers.spotlightMessageHandler.postMessage(payload);
});

})();
