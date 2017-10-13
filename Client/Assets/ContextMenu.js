/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

window.addEventListener('touchstart', function(evt) {
  var target = evt.target;

  var targetLink = target.closest('a');
  var targetImage = target.closest('img');

  if (!targetLink && !targetImage) {
    return;
  }

  var data = {};

  if (targetLink) {
    data.link = targetLink.href;
  }

  if (targetImage) {
    data.image = targetImage.src;
  }

  if (data.link || data.image) {
    webkit.messageHandlers.contextMenuMessageHandler.postMessage(data);
  }
}, true);
