/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

const metadataParser = require("page-metadata-parser/parser.js");

function MetadataWrapper() {
  this.getMetadata = function() {
    let metadata = metadataParser.getMetadata(document, document.URL);

    // Default to using `document.URL` as the "official" URL.
    metadata.url = document.URL;

    // However, if this is an AMP page and a `link[rel="canonical"]`
    // URL is available, use that instead. This is more reliable and
    // produces better results than the URL extracted by the page
    // metadata parser.
    if (location.pathname.startsWith("/amp/")) {
      let canonicalLink = document.querySelector("link[rel=\"canonical\"]");
      let canonicalHref = canonicalLink && canonicalLink.href;
      if (canonicalHref) {
        metadata.url = canonicalHref;
      }
    }

    return metadata;
  };
}

Object.defineProperty(window.__firefox__, "metadata", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new MetadataWrapper())
});
