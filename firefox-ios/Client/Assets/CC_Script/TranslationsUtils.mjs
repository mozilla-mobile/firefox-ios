/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * @typedef {import("./translations").LanguagePair} LanguagePair
 */

/**
 * A set of global static utility functions that are useful throughout the
 * Translations ecosystem within the Firefox code base.
 */
export class TranslationsUtils {
  /**
   * Checks if the language tag string parses as a valid BCP-47 language tag.
   *
   * @param {string} langTag - A BCP-47 language tag.
   * @returns {boolean} - True if the given language tag parses or false if it does not.
   */
  static isLangTagValid(langTag) {
    if (!langTag) {
      return false;
    }

    try {
      new Intl.Locale(langTag);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Normalizes the language tag for comparison within the Translations ecosystem.
   *
   * Prefers to compare languages with a script tag if one is available, only resorting
   * to returning the language tag in isolation if a script tag could not be derived.
   *
   * @param {string} langTag - A BCP-47 language tag.
   * @returns {string} - A BCP-47 language tag normalized for Translations.
   */
  static #normalizeLangTag(langTag) {
    let locale = new Intl.Locale(langTag);

    if (!locale.script) {
      // Attempt to populate a script tag via likely subtags.
      locale = locale.maximize();
    }

    if (locale.script) {
      // If the locale has a script, use it.
      return `${locale.language}-${locale.script}`;
    }

    return locale.language;
  }

  /**
   * Compares two BCP-47 language tags for Translations compatibility.
   *
   * If one language tag belongs to one of our models, and the other
   * language tag is determined to be a match, then it is determined
   * that the model is compatible to for translation with that language.
   *
   * @param {string} lhsLangTag - The left-hand-side language tag to compare.
   * @param {string} rhsLangTag - The right-hand-side language tag to compare.
   *
   * @returns {boolean}
   *  `true`  if the language tags match, either directly or after normalization.
   *  `false` if either tag is invalid or empty, or if they do not match.
   *
   * @see https://datatracker.ietf.org/doc/html/rfc5646#appendix-A
   */
  static langTagsMatch(lhsLangTag, rhsLangTag) {
    if (!lhsLangTag || !rhsLangTag) {
      return false;
    }

    if (lhsLangTag === rhsLangTag) {
      // A simple direct match.
      return true;
    }

    if (lhsLangTag.split("-")[0] !== rhsLangTag.split("-")[0]) {
      // The language components of the tags do not match so there is no need to normalize them and compare.
      return false;
    }

    try {
      return (
        TranslationsUtils.#normalizeLangTag(lhsLangTag) ===
        TranslationsUtils.#normalizeLangTag(rhsLangTag)
      );
    } catch {
      // One of the locales is not valid, just continue on to return false.
    }

    return false;
  }

  /**
   * Serializes a language pair into a unique key that is human readable. This is useful
   * for caching, deduplicating, and logging.
   *
   * e.g.
   *   "en -> fr"
   *   "en -> fr,base"
   *   "zh-Hans,tiny -> fr,base"
   *
   * @param {LanguagePair} languagePair
   */
  static serializeLanguagePair({
    sourceLanguage,
    targetLanguage,
    sourceVariant,
    targetVariant,
  }) {
    let key = sourceLanguage;
    if (sourceVariant) {
      key += `,${sourceVariant}`;
    }
    key += ` -> ${targetLanguage}`;
    if (targetVariant) {
      key += `,${targetVariant}`;
    }
    return key;
  }
}
