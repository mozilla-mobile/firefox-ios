/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
const metadataparser = require("page-metadata-parser/parser.js");

function MetadataWrapper() {
  this.getMetadata = function() {
    return metadataparser.getMetadata(window.document, document.URL);
  };
}

Object.defineProperty(window.__firefox__, 'metadata', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze(new MetadataWrapper(metadataparser))
});
})();
