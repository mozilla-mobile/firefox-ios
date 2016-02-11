/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
  var selectors = {
    title: "head title",
    description: "head meta[name='description'], body p",
  };

  function collectText ($document, selector) {
    var $el = $document.querySelector(selector);
    if ($el) {
      return $el.getAttribute("content") || $el.innerText
    }
  }

  function assemblePayload ($document, selectors) {
    var payload = {};
    for (var key in selectors) {
      payload[key] = collectText($document, selectors[key]) || "";
    }
    return payload;
  }

  window.addEventListener("load", function() {
     var payload = assemblePayload(document, selectors);
     webkit.messageHandlers.spotlightMessageHandler.postMessage(payload);
  });

})()