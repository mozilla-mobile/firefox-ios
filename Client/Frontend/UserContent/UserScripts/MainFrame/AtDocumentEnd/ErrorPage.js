/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// We're required to add the javascript event in a user script
// to be able to get access to the js sandboxed listeners.

"use strict";

const visitOnceButton = document.getElementById(APP_ID_TOKEN + "__firefox__visitOnce")

if (visitOnceButton != null) {
    visitOnceButton.addEventListener('click', function(e) {
        e.preventDefault();
        webkit.messageHandlers.errorPageHelperMessageManager.postMessage({type: "certVisitOnce"})
    });
}
