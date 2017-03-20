/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

if (!window.__firefox__) {
  Object.defineProperty(window, '__firefox__', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {}
  });
}

function MetadataWrapper() {
  var dataURIRegex = /^\s*data:([a-z]+\/[a-z]+(;[a-z\-]+\=[a-z\-]+)?)?(;base64)?,[a-z0-9\!\$\&\'\,\(\)\*\+\,\;\=\-\.\_\~\:\@\/\?\%\s]*\s*$/i;

  function isDataURI(s) {
    return !!s.match(dataURIRegex);
  }
                                                                                  
  function getDataUri(url, callback) {
    var image = new Image();
    image.onload = function() {
      try {
        var canvas = document.createElement('canvas');
        canvas.width = this.naturalWidth; // or 'width' if you want a special/scaled size
        canvas.height = this.naturalHeight; // or 'height' if you want a special/scaled size
        canvas.getContext('2d').drawImage(this, 0, 0);
        var dataURI = canvas.toDataURL();
        callback(dataURI);
      } catch (exception) {
        callback(false);
      }
    };

    image.src = url;
  }

  function metadataCallback(metadata) {
    window.__firefox__.pageMetadata = metadata;
    webkit.messageHandlers.metadataMessageHandler.postMessage(metadata);
  }
 
  this.extractMetadata = function() {
    if (window.__firefox__.pageMetadata) {
      webkit.messageHandlers.metadataMessageHandler.postMessage(window.__firefox__.pageMetadata);
      return;
    }
 
    var metadata = metadataparser.getMetadata(window.document, window.location.href, metadataparser.metadataRules);
    var imageURL = metadata["image_url"];
    if (imageURL) {
      if (isDataURI(imageURL)) {
        metadata["image_data_uri"] = imageURL;
        metadataCallback(metadata);
      } else {
        getDataUri(imageURL, function(dataURI) {
          if (dataURI) {
            metadata["image_data_uri"] = dataURI;
          }
          metadataCallback(metadata);
        });
      }
    } else {
      metadataCallback(metadata);
    }
  };
}

Object.defineProperty(window.__firefox__, 'metadata', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new MetadataWrapper())
});

})();
