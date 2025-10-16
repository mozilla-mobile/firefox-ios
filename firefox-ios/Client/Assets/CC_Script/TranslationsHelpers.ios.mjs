/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";

Node.prototype.ownerGlobal = window;

Object.defineProperty(Node.prototype, "flattenedTreeParentNode", {
  get() {
    return this.parentElement ?? null;
  },
  configurable: true,
});

export const Cu = {
  // NOTE(Issam): Is this enough ? Or maybe we can use WeakRefs.
  isDeadWrapper: (node) => !node?.isConnected,
  isInAutomation: false,
};
globalThis.Cu = Cu;

/// Mock for DOMParser.parseFromSafeString
/// Currently just uses `parseFromString`.
/// `parseFromSafeString` is a gecko API that is not standard.
/// See: https://searchfox.org/firefox-main/source/dom/base/DOMParser.cpp#122
/// TODO(Issam): Implement a safer version (e.g., using DOMPurify to sanitize input HTML)
DOMParser.prototype.parseFromSafeString = function (str, type) {
  return this.parseFromString(str, type);
};

export const setTimeout = globalThis.setTimeout.bind(window);
export const clearTimeout = globalThis.clearTimeout.bind(window);



// TODO(Issam): Implement this for debugging
globalThis.console.createInstance = () => ({
  log: (...whatever) => console.log("createInstance --- ", ...whatever),
  warn: (...whatever) => console.warn("createInstance --- ", ...whatever),
  error: (...whatever) => console.error("createInstance --- ", ...whatever),
  shouldLog: () => false, // TODO(Issam): Maybe enable for webpack dev builds
});

globalThis.ChromeUtils = globalThis.ChromeUtils || {};
globalThis.ChromeUtils.addProfilerMarker = () => { };
globalThis.ChromeUtils.domProcessChild = {
  getActor: () => globalThis,
};
globalThis.ChromeUtils.now = () => performance.now();

/// TODO(Issam): Copy over implementation from: 
/// https://searchfox.org/firefox-main/source/toolkit/components/mozintl/mozIntl.sys.mjs#1044-1058
globalThis.Services = {
  intl: {
    getScriptDirection: () => "ltr",
  }
};

// // QUESTION(Issam): It would be better if the code in the engine ingests these as is.
// // TODO(Issam): Can we send the binary data as is from siwift and use new Uint8Array(byteArray) only 
// // to convert the binary array to a typed one.
// const base64ToArrayBuffer = (base64) => {
//   const binaryString = atob(base64);
//   const length = binaryString.length;
//   const bytes = new Uint8Array(length);
//   for (let i = 0; i < length; i++) {
//     bytes[i] = binaryString.charCodeAt(i);
//   }
//   return bytes;
// };

// // QUESTION(Issam): It would be better if the code in the engine ingests these as is.
// // TODO(Issam): Can we send the binary data as is from siwift and use new Uint8Array(byteArray) only 
// // to convert the binary array to a typed one.
const base64ToArrayBuffer = (base64) => {
  const binary = atob(base64);
  return Uint8Array.from(binary, c => c.charCodeAt(0)).buffer;
}

// // NOTE(Issam): Wasm is bundled using webpack. Language models are fetched from swift.
// // Is this a good approach ?
// export const getAllModels = async (sourceLanguage, targetLanguage) => {
//   // NOTE(Issam): Most processing is done in swift. If we manage to accept base64 encoded models
//   // Then we can omit the processing here all together.
//   // TODO(Issam): models in base64 to array buffer
//   // languageModelFiles: {
//   //     lex: {buffer: ""}
//   //     vocab: {buffer: ""}
//   //     model: {buffer: ""}
//   // }
//   const modelsForLanguagePair =
//     await webkit.messageHandlers.translationsBackground.postMessage({
//       type: "getModels",
//       payload: {
//         sourceLanguage,
//         targetLanguage,
//       },
//     });

//   const languageModelFiles = modelsForLanguagePair.languageModelFiles;
//   for (const model of Object.values(languageModelFiles)) {
//     model.buffer = base64ToArrayBuffer(model.buffer);
//   }
//   return modelsForLanguagePair;
// };

globalThis.TE_getLogLevel = () => { };
globalThis.TE_log = (message) => console.log("TE_log ---- ", message);
globalThis.log = (message) => console.log("log ---- ", message);

globalThis.TE_logError = (...error) =>
  console.error("TE_error ---- ", ...error);
globalThis.TE_getLogLevel = () => { };
globalThis.TE_destroyEngineProcess = () => { };
globalThis.TE_reportEnginePerformance = () => { };
globalThis.TE_requestEnginePayload = async ({ sourceLanguage, targetLanguage  }) => {
  const modelsURL = `translations://app/models?from=${encodeURIComponent(sourceLanguage)}&to=${encodeURIComponent(targetLanguage)}`;
  const modelsResponse = await fetch(modelsURL);
  if (!modelsResponse.ok) throw new Error(`Model fetch failed: ${modelsResponse.status}`);
  const translationModelPayloads = await modelsResponse.json();
  // TODO(Issam): I hate this extra processing we should just send it as a binary array. 
  const processedPayloads = processTranslationPayloads(translationModelPayloads);
  // TODO(Issam): Use Promise.all to parallelize this with fetching the wasm so we don't wait for one then the other.
  const translatorURL = `translations://app/translator`;
  const translatorResponse = await fetch(translatorURL);
  if (!translatorResponse.ok) throw new Error(`Translator fetch failed: ${translatorResponse.status}`);
  const bergamotTranslator = await translatorResponse.json();

  return {
    bergamotWasmArrayBuffer: base64ToArrayBuffer(bergamotTranslator.wasm),
    translationModelPayloads: processedPayloads,
    isMocked: false,
  };
};
globalThis.TE_reportEngineStatus = () => { };
globalThis.TE_resolveForceShutdown = () => { };
globalThis.TE_addProfilerMarker = () => { };


// TODO(Issam): We should figure a better way to do this instead of all the extra processing here.
// Maybe we can send the binary data as is from swift and use new Uint8Array(byteArray) only 
// to convert the binary array to a typed one.
const processTranslationPayloads = (payloads) =>
  payloads.map(payload => {
    const processedFiles = {};
    for (const [type, file] of Object.entries(payload.languageModelFiles)) {
      processedFiles[type] = {
        ...file,
        buffer: base64ToArrayBuffer(file.buffer),
      };
    }
    return { ...payload, languageModelFiles: processedFiles };
  });

// NOTE(Issam): Calling new Worker(url) will cause a security error since we are loading from an unsafe context.
// To bypass this we inline the worker and override the Worker constructor. This way we don't have to touch the shared code.
// We are only calling this to load translations-engine.worker.js for now, so it's hardcoded
const OriginalWorker = globalThis.Worker;
globalThis.Worker = class extends OriginalWorker {
  constructor(url, options) {
    if (url.endsWith("translations-engine.worker.js")) {
      const translationsWorker = require("Assets/CC_Script/translations-engine.worker.js");
      return new translationsWorker();
    }
    return new OriginalWorker(url, options);
  }
};

// NOTE(Issam): importScripts is resolved at runtime which is problematic. The best solution I found for this is to:
// - Override it to use require so webpack can build the deps graph.
// - Use script-loader to expose loadBergamot to the worker since it's not an es module.
globalThis.importScripts = (moduleURI) => {
  const moduleName = moduleURI.split("/").pop();
  require(`script-loader!./${moduleName}`);
};