// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
"use strict";

/// Maximum number of characters to include in the sample.
/// `cld2` is designed for at least 200+ characters for reliable detection.
/// Reference: https://github.com/CLD2Owners/cld2?tab=readme-ov-file#summary
/// Apple’s `NLLanguageRecognizer` documentation states that confidence improves with more input but does not specify a maximum.
/// Apple research has shown that accuracy plateaus around 50 characters with no meaningful gains beyond that.
/// Reference: https://machinelearning.apple.com/research/language-identification-from-very-short-strings
/// 2000 characters is chosen as a safe upper bound to ensure sufficient context for mixed-language or noisy inputs while maintaining performance.
///
/// NOTE: For phase 2, we can experiment with a text segmenter like `Intl.Segmenter` to ensure we are not cutting off words.
/// For more context: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter/Segmenter
const MAX_LANGUAGE_SAMPLE_CHARS = 2000;

/// Exposed helper to get a language sample after the document is ready.
/// This is intended to be used in swift and to be passed to a language detection API.
export const getLanguageSampleWhenReady = async () => {
  await documentReady();
  return getLanguageSample();
};

/// Extracts a sample of text from the current page to help with language detection.
/// To better capture the overall linguistic characteristics of the page, the extracted sample
/// consists of two sections of the page content, one from the start and one from the middle.
/// This sample is forwarded to a language detector ( e.g `NLLanguageRecognizer` or `cld2` )
const getLanguageSample = (maxChars = MAX_LANGUAGE_SAMPLE_CHARS) => {
  /// NOTE: This is enough for text sampling. If we want extra processing of the text, 
  /// beyond just collapsing whitespaces, we can use `extractContent` from `Summarizer.js`.
  const text = (document.body?.innerText || document.documentElement?.innerText || "")
    .replace(/\s+/g, " ")
    .trim();

  if(text.length <= maxChars) return text;

  /// NOTE: For pages longer than maxChars, take two samples:
  /// - Start sample: first N characters (where N = maxChars/2 - 1). 
  //    The -1 is to account for the whitespace separator when we join the samples.
  /// - Middle sample: N characters starting from the middle of the document.
  /// Extracting two samples helps capture a more representative linguistic profile of the page.
  const sampleSize = Math.floor(maxChars / 2 - 1);
  const midpoint = Math.floor(text.length / 2);

  const startSample = text.slice(0, sampleSize);
  const middleSample = text.slice(midpoint, midpoint + sampleSize); 
  return (startSample + " " + middleSample).trim();
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
