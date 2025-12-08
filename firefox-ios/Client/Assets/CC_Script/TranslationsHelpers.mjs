/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";

/// NOTE: In Gecko, EventTarget and Node objects have a Chrome-only
/// `ownerGlobal` attribute that returns the global window (WindowProxy)
/// associated with the node. This is mostly used in privileged (chrome) code.
///
/// In normal web JS environments, all DOM nodes already belong to a single
/// global `window`, so we can safely emulate this by returning `window`.
///
/// For more context, see:
/// - https://searchfox.org/firefox-main/rev/6abddcb0a5076c3b888686ede6f4cf7d082460d3/dom/webidl/EventTarget.webidl#65-71
Node.prototype.ownerGlobal = window;

/// NOTE: In Gecko, Node objects have a Chrome-only `flattenedTreeParentNode`
/// attribute that returns the parent node in the flattened DOM tree.
///
/// In normal web JS environments, the flattened tree parent is equivalent
/// to the `parentElement` property, so we can safely emulate this by
/// returning `this.parentElement`.
Object.defineProperty(Node.prototype, "flattenedTreeParentNode", {
  get() {
    return this.parentElement ?? null;
  },
  configurable: true,
});

export const Cu = {
  isDeadWrapper: (node) => !node?.isConnected,
  isInAutomation: false,
};
globalThis.Cu = { ...globalThis.Cu, ...Cu };

/// Polyfill for Gecko's non-standard DOMParser.parseFromSafeString.
/// In Gecko, this ensures the parsed document uses the same principal
/// as the owner global.
/// For normal web JS, we simply forward to parseFromString.
DOMParser.prototype.parseFromSafeString = function (str, type) {
  return this.parseFromString(str, type);
};

export const setTimeout = globalThis.setTimeout.bind(window);
export const clearTimeout = globalThis.clearTimeout.bind(window);

/// NOTE: Polyfill for Gecko's non-standard console.createInstance.
/// For reference, see:
/// - https://firefox-source-docs.mozilla.org/toolkit/javascript-logging.html
globalThis.console.createInstance = () => ({
  log: (...params) => console.log("createInstance --- ", ...params),
  warn: (...params) => console.warn("createInstance --- ", ...params),
  error: (...params) => console.error("createInstance --- ", ...params),
  shouldLog: () => false,
});

globalThis.TE_getLogLevel = () => { };
globalThis.TE_log = (message) => console.log("TE_log ---- ", message);
globalThis.log = (message) => console.log("log ---- ", message);
globalThis.TE_logError = (...error) =>
  console.error("TE_error ---- ", ...error);

/// NOTE: Polyfills for various ChromeUtils and TE_* functions used by
/// translations-engine.js in Gecko.
globalThis.ChromeUtils = globalThis.ChromeUtils || {};
globalThis.ChromeUtils.addProfilerMarker = () => { };
globalThis.ChromeUtils.domProcessChild = {
  getActor: () => globalThis,
};
globalThis.ChromeUtils.now = () => performance.now();
globalThis.Services = { ...globalThis.Services,  intl: { getScriptDirection: () => "ltr" } };


/// NOTE: Stubs for TE_* functions used by translations-engine.js in Gecko.
/// These are no-ops or empty implementations as needed (for now).
globalThis.TE_getLogLevel = () => { };
globalThis.TE_destroyEngineProcess = () => { };
globalThis.TE_reportEnginePerformance = () => { };
globalThis.TE_reportEngineStatus = () => { };
globalThis.TE_resolveForceShutdown = () => { };
globalThis.TE_addProfilerMarker = () => { };
/// NOTE: Implementation for TE_requestEnginePayload used by translations-engine.js in Gecko.
/// This fetches the translation models and translator WASM from the app's
/// translations:// URLs and returns them in the expected format.
globalThis.TE_requestEnginePayload = async ({ sourceLanguage, targetLanguage }) => {
  let receivedEngineRequest = performance.now();
  const params = new URLSearchParams({ from: sourceLanguage, to: targetLanguage });
  const modelsURL = `translations://app/models?${params.toString()}`;
  const translatorURL = `translations://app/translator`;

  const [modelsData, translatorData] = await Promise.all([
    fetchJson(modelsURL, "Model metadata"),    
    fetchBinary(translatorURL, "Translator WASM"),
  ]);

  const [processedPayloads, bergamotWasmArrayBuffer] = await Promise.all([
    processTranslationPayloads(modelsData),
    translatorData,
  ]);

  return {
    bergamotWasmArrayBuffer,
    translationModelPayloads: processedPayloads,
    isMocked: false,
  };
};

/// Helper to fetch resource with descriptive error messages
const fetchResource = async (url, resourceName, type = "json") => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to fetch ${resourceName}: ${response.status} ${response.statusText}`);
  }
  return response[type]();
};

/// Helper to fetch JSON data with descriptive error messages
const fetchJson   = (url, name) => fetchResource(url, name, "json");
/// Helper to fetch binary data with descriptive error messages
const fetchBinary = (url, name) => fetchResource(url, name, "arrayBuffer");

/// Process translation payloads by fetching model buffers and attaching them to payloads.
const processTranslationPayloads = async (payloads) => {
  const result = [];
  for (const payload of payloads) {
    const filesOut = {};
    for(const [type, file] of Object.entries(payload.languageModelFiles)) {
      const buffer = await fetchBinary(`translations://app/models-buffer?recordId=${file.record.id}`, "Model buffer fetch");
      filesOut[type] = { ...file, buffer };
    }
    result.push({...payload, languageModelFiles: filesOut});
  }
  return result;
};