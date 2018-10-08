/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const DEFAULT_LANGUAGE = WEB_EXTENSION_MANIFEST["default_locale"] || "en";

const i18n = {
  getAcceptLanguages: noimpl("getAcceptLanguages"),
  getMessage: function(messageName, substitutions) {
    let localizations = WEB_EXTENSION_LOCALES[WEB_EXTENSION_SYSTEM_LANGUAGE] || WEB_EXTENSION_LOCALES[DEFAULT_LANGUAGE] || {};
    let localization = localizations[messageName];
    if (!localization) {
      console.error("Localized message not found for '" + messageName + "'");
      return "";
    }

    // This implementation borrows extensively from mozilla-central:
    // /toolkit/components/extensions/ExtensionCommon.jsm
    let message = localization.message || "";
    if (!message.includes("$")) {
      return message;
    }

    let isPlainObject = obj => (obj && typeof obj === "object");

    // Substitutions are case-insensitive, so normalize all of their names
    // to lower-case.
    let placeholders = new Map();
    if (isPlainObject(localization.placeholders)) {
      for (let key of Object.keys(localization.placeholders)) {
        placeholders.set(key.toLowerCase(), localization.placeholders[key]);
      }
    }

    let replacePlaceholdersWithIndices = (match, name) => {
      let replacement = placeholders.get(name.toLowerCase());
      if (isPlainObject(replacement) && "content" in replacement) {
        return replacement.content;
      }
      return "";
    };

    let messageWithIndices = message.replace(/\$([A-Za-z0-9@_]+)\$/g, replacePlaceholdersWithIndices);

    if (!messageWithIndices.includes("$")) {
      return messageWithIndices;
    }

    if (!Array.isArray(substitutions)) {
      substitutions = [substitutions];
    }

    let replaceIndicesWithSubstitutions = (matched, index, dollarSigns) => {
      if (index) {
        // This is not quite Chrome-compatible. Chrome consumes any number
        // of digits following the $, but only accepts 9 substitutions. We
        // accept any number of substitutions.
        index = parseInt(index, 10) - 1;
        return index in substitutions ? substitutions[index] : "";
      }
      // For any series of contiguous `$`s, the first is dropped, and
      // the rest remain in the output string.
      return dollarSigns;
    };

    return messageWithIndices.replace(/\$(?:([1-9]\d*)|(\$+))/g, replaceIndicesWithSubstitutions);
  },
  getUILanguage: function() {
    return WEB_EXTENSION_SYSTEM_LANGUAGE;
  },
  detectLanguage: noimpl("detectLanguage")
};

window.browser.i18n = i18n;
