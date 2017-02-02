/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * Transport postMessage events from the fxa-content-server to the embedding
 * webview.
 */

"use strict";

function handleAccountsCommand(evt) {
    webkit.messageHandlers.accountsCommandHandler.postMessage({ type: evt.type, detail: evt.detail });
};
window.addEventListener("FirefoxAccountsCommand", handleAccountsCommand);
