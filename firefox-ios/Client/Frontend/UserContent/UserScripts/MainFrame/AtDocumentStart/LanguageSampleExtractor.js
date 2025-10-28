// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
"use strict";

/// Maximum number of characters to include in the sample.
/// NOTE: For phase 2, we can experiment with a text segmenter to specify words instead.
const MAX_LANGUAGE_SAMPLE_CHARS = 3000;

/// Extracts a sample of text from the current page to help with language detection.
/// To better capture the overall linguistic characteristics of the page, 
/// the extracted sample consists of two sections of the page content, one from the start and one from the middle.
/// This sample is forwarded to a language detector ( e.g `NLLanguageRecognizer` or `cld3` )
const getLanguageSample = (maxChars = MAX_LANGUAGE_SAMPLE_CHARS) => {
  /// NOTE: This is enough for text sampling. If we want extra processing of the text, 
  /// beyond just collapsing whitespaces, we can use `extractContent` from the summarizer.
  const text = (document.body?.innerText || document.documentElement?.innerText || "")
    .replace(/\s+/g, " ")
    .trim();

  if(text.length <= maxChars) return text;

  const sampleSize = Math.floor(maxChars / 2);
  const midpoint = Math.floor(text.length / 2);

  const startSample = text.slice(0, sampleSize);
  const middleSample = text.slice(midpoint, midpoint + sampleSize); 
  return (startSample + "\n" + middleSample).trim();
};

/// Helper function to wait for document to be ready before running checks.
/// Returns a Promise that resolves when the document is ready.
const documentReady = () =>  new Promise(resolve => {
  if (document.readyState !== "loading") {
    resolve();
  } else {
    document.addEventListener("readystatechange", () => {
      if (document.readyState === "complete") {
        resolve();
      }
    });
  }
});

/// Exposed helper to get a language sample after the document is ready.
export const getLanguageSampleWhenReady = async () => {
  await documentReady();
  return getLanguageSample();
};