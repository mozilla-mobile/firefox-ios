/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {

 "use strict";
 console.log('registering onclose')

 var onclose = function(event) {
 console.log('firing onclose')
 webkit.messageHandlers.windowEventsMessageHandler.postMessage('close');
 };

 webkit.messageHandlers.windowEventsMessageHandler.postMessage('test');
 addEventListener('closed', onclose);
}) ();
