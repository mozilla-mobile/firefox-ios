/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
if (typeof window.__firefox__.download == "undefined") {
Object.defineProperty(window.__firefox__, "download", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: function(url, appIdToken, fileName = null) {
    if (appIdToken !== APP_ID_TOKEN) {
      return;
    }

    function getLastPathComponent(url) {
      return url.split("/").pop();
    }

    function blobToBase64String(blob, callback) {
      var reader = new FileReader();
      reader.onloadend = function() {
        callback(this.result.split(",")[1]);
      };

      reader.readAsDataURL(blob);
    }

    if (url.startsWith("blob:")) {
      var xhr = new XMLHttpRequest();
      xhr.open("GET", url, true);
      xhr.responseType = "blob";
      xhr.onload = function() {
        if (this.status !== 200) {
          return;
        }

        var blob = this.response;
        
        // Checking if the blob is a pkpass (Passbook Pass) or download, if not, continue navigation
        if (blob.type != "application/vnd.apple.pkpass" && !fileName) {
          window.location.href = url;
          return
        }
      
        blobToBase64String(blob, function(base64String) {
          webkit.messageHandlers.downloadManager.postMessage({
            url: url,
            mimeType: blob.type,
            size: blob.size,
            base64String: base64String,
            fileName
          });
        });
      };

      xhr.send();
      return;
    }

    var link = document.createElement("a");
    link.href = url;
    link.dispatchEvent(new MouseEvent("click"));
  }
});
}

document.addEventListener("click", (event) => {
  if (event.target.localName == "a" && event.target.hasAttribute("download")) {
    event.preventDefault();
    // The APP_ID_TOKEN is a unique identifier associated with the app used by scripts to verify the *app*
    // (not JS on the web) is calling into them.
    window.__firefox__.download(event.target.href, APP_ID_TOKEN, event.target.download)
  }
})
