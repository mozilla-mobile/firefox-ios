/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function () {

if (!window.__firefox__) {
    window.__firefox__ = {};
}

var MetadataWrapper = function () {

    function extractMetadata() {
        if (window.__firefox__.pageMetadata) {
            webkit.messageHandlers.metadataMessageHandler.postMessage(window.__firefox__.pageMetadata);
            return;
        }

        var metadataCallback = function(metadata) {
            window.__firefox__.pageMetadata = metadata;
            webkit.messageHandlers.metadataMessageHandler.postMessage(metadata);
        }

        var metadata = metadataparser.getMetadata(window.document, window.location.href, metadataparser.metadataRules);

        var iconURL = metadata["icon_url"];
        var imageURL = metadata["image_url"];
        var iconLoaded = false, imageLoaded = false
        if (iconURL) {
            getDataUri(iconURL, function(dataURI) {
                if (dataURI) {
                    metadata["icon_data_uri"] = dataURI;
                }
                if (imageLoaded) {
                    metadataCallback(metadata);
                } else {
                    iconLoaded = true
                }
            });
        } 
        else { 
            iconLoaded = true; 
        }

        if (imageURL) {
            getDataUri(imageURL, function(dataURI) {
                if (dataURI) {
                    metadata["image_data_uri"] = dataURI;
                }
                if (iconLoaded) {
                    metadataCallback(metadata);
                } else {
                    imageLoaded = true
                }
            });
        } 
        else if (iconLoaded) { 
            imageLoaded = true; 
            metadataCallback(metadata);
        }

    }

    return {
        extractMetadata: extractMetadata
    };

    function getDataUri(url, callback) {
        var image = new Image();

        image.onload = function () {
            try {
                var canvas = document.createElement('canvas');
                canvas.width = this.naturalWidth; // or 'width' if you want a special/scaled size
                canvas.height = this.naturalHeight; // or 'height' if you want a special/scaled size

                canvas.getContext('2d').drawImage(this, 0, 0);

                var dataURI = canvas.toDataURL();
                callback(dataURI);
            } catch (exception) {
                callback(false)
            }
        };

        image.src = url;
    }

    return {
        extractMetadata: extractMetadata
    };
};

window.__firefox__.metadata = new MetadataWrapper();

})();
