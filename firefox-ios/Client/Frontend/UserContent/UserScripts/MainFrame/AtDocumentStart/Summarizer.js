// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
import { Readability, isProbablyReaderable} from "@mozilla/readability";
import { findRecipeJSONLD } from "./JSONLD";

const ALLOWED_LANGS = ["en"];

const CONTENT_TYPES = {generic: "generic", recipe: "recipe"};

const isPageLanguageSupported = () => {
  // Attempt to use the <html> lang attribute. 
  // When the lang attribute is not set we get "". In that case, default to "en".
  const rawLang = document.documentElement.lang?.trim() || "en";
  try {
    const locale = new Intl.Locale(rawLang);
    return ALLOWED_LANGS.includes(locale.language);
  } catch {
    return true;
  }
}

const extractContent = () => {
  const uri = {
    spec: document.location.href,
    host: document.location.host,
    prePath: document.location.protocol + "//" + document.location.host,
    scheme: document.location.protocol.substr(
      0,
      document.location.protocol.indexOf(":")
    ),
    pathBase:
      document.location.protocol +
      "//" +
      document.location.host +
      location.pathname.substr(0, location.pathname.lastIndexOf("/") + 1),
  };

  const docStr = new XMLSerializer().serializeToString(document);

  const DOMPurify = require("dompurify");
  const clean = DOMPurify.sanitize(docStr, { WHOLE_DOCUMENT: true });
  const doc = new DOMParser().parseFromString(clean, "text/html");
  const readability = new Readability(uri, doc);
  const readabilityResult = readability.parse();
  const rawContent = readabilityResult.textContent ?? readabilityResult.content;
  return rawContent
    .trim()
    // Replace duplicate whitespace with either a single newline or space
    .replace(/(\s*\n\s*)|\s{2,}/g, (_, newline) => (newline ? "\n" : " "));
};

/**
 * Helper function to wait for document to be ready before running checks.
 * Returns a Promise that resolves when the document is ready.
 */
const documentReady = () =>  new Promise(resolve => {
  if (document.readyState !== "loading") {
    resolve();
  } else {
    document.addEventListener("readystatechange", () => {
      if (document.readyState !== "loading") {
        resolve();
      }
    }, { once: true });
  }
});

/**
 * Count the number of words in a text string.
 * @param {string} text
 * @returns {number}
 */
const countWords = (text) => {
  return text.trim().split(/\s+/).filter(Boolean).length;
};


/**
 * Checks document summarization eligibility.
 * Returns an object with `canSummarize`, `reason`, and `wordCount`.
 * @param {number} maxWords - Maximum number of words allowed for summarization.
 * @returns {{ canSummarize: boolean, reason: string, wordCount: number }}
 */
const checkSummarization = async (maxWords) => {
  // 0. Document should be ready before we do anything.
  await documentReady();

  // 1. Check if the page language is supported.
  if (!isPageLanguageSupported()) {
    return {
      canSummarize: false,
      reason: "documentLanguageUnsupported",
      wordCount: 0,
    };
  }

  // 1. Readerable check
  if (!isProbablyReaderable(document)) {
    return {
      canSummarize: false,
      reason: "documentNotReadable",
      wordCount: 0,
    };
  }

  // 2. If it's a recipe return jsonld instead
  const recipe = findRecipeJSONLD();
  if (recipe) {
    const recipeString = JSON.stringify(recipe);
    return {
      canSummarize: true,
      reason: null,
      wordCount: countWords(recipeString),
      textContent: recipeString,
      contentType: CONTENT_TYPES.recipe,
    };
  }

  // 3. Extract and count words
  const text = extractContent();
  const wordCount = countWords(text);

  if (wordCount > maxWords) {
    return {
      canSummarize: false,
      reason: "contentTooLong",
      wordCount,
    };
  }

  return { 
    canSummarize: true, 
    reason: null, 
    wordCount, 
    textContent: text,
    contentType: CONTENT_TYPES.generic
  };
};


Object.defineProperty(window.__firefox__, "Summarizer", {
  enumerable: false,
  configurable: false,
  writable: false,
  value: Object.freeze({checkSummarization})
});