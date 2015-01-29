/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Transport postMessage events from the fxa-content-server to the embedding
 * webview.
 */

"use strict";

// We use "load" as a temporary proxy for the forth-coming "ready to paint"
// event from the fxa-content-server, tracked by
// https://github.com/mozilla/fxa-content-server/issues/2066.  Since
// fxa-content-server XHR loads may not have completed at "load" time, we push
// the event back 1000ms.
function handleLoadEvent(evt) {
    window.removeEventListener("load", handleLoadEvent);
    window.setTimeout(function() {
        webkit.messageHandlers.accountsCommandHandler.postMessage({ type: "load", detail: {command: "load", data: {}}});
    }, 1000);
}
window.addEventListener("load", handleLoadEvent);

function handleAccountsCommand(evt) {
    webkit.messageHandlers.accountsCommandHandler.postMessage({ type: evt.type, detail: evt.detail });
};
window.addEventListener("FirefoxAccountsCommand", handleAccountsCommand);
