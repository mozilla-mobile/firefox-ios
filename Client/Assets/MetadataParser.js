/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function () {

if (!window.__firefox__) {
    window.__firefox__ = {};
}

var MetadataWrapper = function () {

    function extractMetadata() {
        var metadata = metadataparser.getMetadata(window.document, window.location.href, metadataparser.metadataRules);
        webkit.messageHandlers.metadataMessageHandler.postMessage(metadata);
    }

    return {
        extractMetadata: extractMetadata
    };
};

window.__firefox__.metadata = new MetadataWrapper();

})();