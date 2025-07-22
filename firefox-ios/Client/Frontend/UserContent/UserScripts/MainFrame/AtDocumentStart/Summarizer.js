/* vim: set ts=2 sts=2 sw=2 et tw=80: */
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

"use strict";
import { Readability } from "@mozilla/readability";

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
  return readabilityResult.textContent ?? readabilityResult.content;
};

/**
 * Checks document summarization eligibility.
 * Returns an object with `canSummarize`, `reason`, and `wordCount`.
 * @param {number} maxWords - Maximum number of words allowed for summarization.
 * @returns {{ canSummarize: boolean, reason: string, wordCount: number }}
 */
const checkSummarization = (maxWords = MAX_DOCUMENT_LENGTH_IN_WORDS) => {
  // 0. Document should be ready before we do anything.
  if (document.readyState === "loading") {
    return {
      canSummarize: false,
      reason: "documentNotReady",
      wordCount: 0,
    };
  }

  // 1. Readerable check
  if (!isProbablyReaderable(document)) {
    return {
      canSummarize: false,
      reason: "documentNotReadeable",
      wordCount: 0,
    };
  }

  // 2. Extract and count words
  const text = extractContent();
  const wordCount = text.trim().split(/\s+/).filter(Boolean).length;

  if (wordCount > maxWords) {
    return {
      canSummarize: false,
      reason: "contentTooLong",
      wordCount,
    };
  }

  return { canSummarize: true, reason: null, wordCount };
};

window.checkSummarization = checkSummarization;
