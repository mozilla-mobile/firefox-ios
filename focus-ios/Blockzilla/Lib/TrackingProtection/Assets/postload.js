/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

var messageHandler = window.webkit.messageHandlers.focusTrackingProtectionPostLoad
var sendMessage = function(url) { messageHandler.postMessage({ url: url }) }

// Send back the sources of every script and image in the dom back to the host applicaiton
Array.prototype.map.call(document.scripts, function(t) { return t.src }).forEach(sendMessage)
Array.prototype.map.call(document.images, function(t) { return t.src }).forEach(sendMessage)
