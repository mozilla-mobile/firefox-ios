/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";

const metadataParser = require("page-metadata-parser/parser.js");

function MetadataWrapper() {
  this.getMetadata = function() {
    let metadata = metadataParser.getMetadata(document, location.origin);

    // Set metadata.url to document URL by default
    metadata.url = document.URL;

    // No need to do anything if not an amp page
    if (!location.pathname.startsWith("/amp/")) {
      return metadata;
    }

    // Return metadata as is if no canonical link or href were found
    const canonicalLink = document.querySelector("link[rel='canonical']");
    if (!canonicalLink?.href) {
      return metadata;
    }

    // At this stage we are sure the canonical href exists
    try {
      const canonicalUrl = new URL(canonicalLink.href, location);
      if (canonicalUrl.protocol.match(/^https?:$/)) {
        metadata.url = canonicalLink.href;
      }
    } catch (error) {
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
