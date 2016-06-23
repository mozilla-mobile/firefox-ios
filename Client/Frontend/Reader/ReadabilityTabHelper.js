/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
    // To keep this file readable and Readability.js separate, since we import it from an external
    // repository, we merge it in this file programatically. We do not include it as a user script
    // because that means pages can mess with it; by including it below, it is part of an anonymous
    // function that only exists once.

    %READABILITYJS%

    var uri = {
        spec: document.location.href,
        host: document.location.host,
        prePath: document.location.protocol + "//" + document.location.host, // TODO This is incomplete, needs username/password and port
        scheme: document.location.protocol.substr(0, document.location.protocol.indexOf(":")),
        pathBase: document.location.protocol + "//" + document.location.host + location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1)
    }

    // document.cloneNode() can cause the webview to break (bug 1128774).
    // Serialize and then parse the document instead.
    var docStr = new XMLSerializer().serializeToString(document);
    var doc = new DOMParser().parseFromString(docStr, "text/html");

    var readability = new Readability(uri, doc);
    var readabilityResult = readability.parse();

    webkit.messageHandlers.readabilityMessageHandler.postMessage(readabilityResult);
})();
