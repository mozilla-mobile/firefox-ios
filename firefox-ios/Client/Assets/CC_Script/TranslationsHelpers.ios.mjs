/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import "resource://gre/modules/shared/Helpers.ios.mjs";
import { ZstdInit } from '@oneidentity/zstd-js/wasm/decompress/index.js';

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

globalThis.TE_getLogLevel = () => { };
globalThis.TE_log = (message) => console.log("TE_log ---- ", message);
globalThis.log = (message) => console.log("log ---- ", message);

globalThis.TE_logError = (...error) =>
  console.error("TE_error ---- ", ...error);
globalThis.TE_getLogLevel = () => { };
globalThis.TE_destroyEngineProcess = () => { };
globalThis.TE_reportEnginePerformance = () => { };
globalThis.TE_requestEnginePayload = async ({ sourceLanguage, targetLanguage }) => {
  let receivedEngineRequest = performance.now();
  const params = new URLSearchParams({ from: sourceLanguage, to: targetLanguage });
  const modelsURL = `translations://app/models?${params.toString()}`;
  const translatorURL = `translations://app/translator`;

  // Fetch both in parallel
  const [modelsData, translatorData] = await Promise.all([
    fetchJson(modelsURL, "Model metadata"),    
    fetchBinary(translatorURL, "Translator WASM"),
  ]);

  console.log("oooo --- [timestamp] TE_requestEnginePayload 1", performance.now() - receivedEngineRequest);
  /// NOTE(Issam): base64 is very slow to decode this is a bottleneck. 
  /// Looking at logs fetching takes < 1s but this processing hangs for a while.
  /// We should fetch the wasm directly and .arrayBuffer() it directly.
  /// For the models we should fetch the json and the binary buffer separately.
  /// And we can construct the payloads here.
  /// Right now on the japanese site it can take up to 36250ms to decode the models according to performance.now() - receivedEngineRequest.
  const [processedPayloads, bergamotWasmArrayBuffer] = await Promise.all([
    processTranslationPayloads(modelsData),
    translatorData,
  ]);

  console.log("oooo --- [timestamp] TE_requestEnginePayload 2", performance.now() - receivedEngineRequest);
  return {
    bergamotWasmArrayBuffer,
    translationModelPayloads: processedPayloads,
    isMocked: false,
  };
};
globalThis.TE_reportEngineStatus = () => { };
globalThis.TE_resolveForceShutdown = () => { };
globalThis.TE_addProfilerMarker = () => { };


/// Helper to fetch JSON data with descriptive error messages
const fetchJson = async (url, resourceName) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(
      `Failed to fetch ${resourceName}: ${response.status} ${response.statusText}`
    );
  }
  return response.json();
}

/// Helper to fetch JSON data with descriptive error messages
const fetchBinary = async (url, resourceName) => {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(
      `Failed to fetch ${resourceName}: ${response.status} ${response.statusText}`
    );
  }
  return response.arrayBuffer();
}

// TODO(Issam): We should figure a better way to do this instead of all the extra processing here.
// Maybe we can send the binary data as is from swift and use new Uint8Array(byteArray) only 
// to convert the binary array to a typed one.
// const processTranslationPayloads = async (payloads) =>
//   payloads.map(payload => {
//     const processedFiles = {};
//     for (const [type, file] of Object.entries(payload.languageModelFiles)) {
//       processedFiles[type] = {
//         ...file,
//         buffer: base64ToArrayBuffer(file.buffer),
//       };
//     }
//     return { ...payload, languageModelFiles: processedFiles };
//   });

// const processTranslationPayloads = async (payloads) =>
//   payloads.map(payload => {
//     const processedFiles = {};
//     console.log("oooo --- processTranslationPayloads payload ", payload);
//     for (const [type, file] of Object.entries(payload.languageModelFiles)) {
//       const buffer = await fetch(`translations://app/model?bufferId=${file.record.id}`)
//       processedFiles[type] = { ...file, bufffer: await buffer.arrayBuffer() };
//       console.log("oooo --- processTranslationPayloads file ", file.record.id);
//     }
//     return { ...payload, languageModelFiles: processedFiles };
//   });


/// NOTE(Issam): Fully parallel: all payloads in parallel, and all files within each payload in parallel.
// const processTranslationPayloads = async (payloads) => {
//   return Promise.all(
//     payloads.map(async (payload) => {
//       const entries = Object.entries(payload.languageModelFiles);

//       const processedEntries = await Promise.all(
//         entries.map(async ([type, file]) => {
//           const res = await fetch(`translations://app/models-buffer?id=${file.record.id}`);
//           if (!res.ok) throw new Error(`Fetch failed for ${file.record.id}: ${res.status}`);
//           const buffer = await res.arrayBuffer();
//           console.log("zzzz --- processTranslationPayloads fetched buffer for ", file.record.id);
//           // const compressed = new Uint8Array(buffer);
//           // const decompressed = fzstd.decompress(compressed);
//           return [type, { ...file, buffer }];
//         })
//       );
//       return {
//         ...payload,
//         languageModelFiles: Object.fromEntries(processedEntries),
//       };
//     })
//   );
// };

// const processTranslationPayloads = async (payloads) => {
//   let receivedEngineRequest = performance.now();
//   const result = [];
//   console.log("oooo --- [timestamp] processTranslationPayloads 1", performance.now() - receivedEngineRequest);
//   for (const payload of payloads) {
//     const filesOut = {};

//     for (const [type, file] of Object.entries(payload.languageModelFiles)) {
//       const url = `translations://app/models-buffer?id=${file.record.id}`;
//       const res = await Promise.any([fetch(url), fetch(url), fetch(url), fetch(url), fetch(url)]);
//       if (res.status !== 0) {
//         throw new Error(`Fetch failed for ${file.record.id}: ${res.status}`);
//       }
//       const buffer = await res.arrayBuffer();
//       const compressed = new Uint8Array(buffer);
//       const decompressed = fzstd.decompress(compressed);
//       console.log("oooo --- [timestamp] processTranslationPayloads 2", performance.now() - receivedEngineRequest);
//       filesOut[type] = { ...file, buffer: decompressed.buffer };
//     }

//     result.push({
//       ...payload,
//       languageModelFiles: filesOut,
//     });
//   }
//   console.log("oooo --- [timestamp] processTranslationPayloads 3", performance.now() - receivedEngineRequest);
//   return result;
// };

const processTranslationPayloads = async (payloads) => {
  const { ZstdSimple, ZstdStream } = await ZstdInit();
console.log("oooo --- ZstdInit done", ZstdSimple, ZstdStream, ZstdInit);
  const result = [];
  for (const payload of payloads) {
    const filesOut = {};
    for(const [type, file] of Object.entries(payload.languageModelFiles)) {
      const buffer = await fetchBinary(`translations://app/models-buffer?id=${file.record.id}`, "Model buffer fetch");
      console.log("iiiii  1 processTranslationPayloads --- done and now waiting ???");
      // const compressed = new Uint8Array(buffer);
      // console.log("iiiii  2 processTranslationPayloads --- done and now waiting ???");
      // const decompressed = ZstdSimple.decompress(compressed);      
      // console.log("iiiii  3 processTranslationPayloads --- done and now waiting ???");
      filesOut[type] = { ...file, buffer: buffer };
      // console.log("oooo --- processTranslationPayloads processing modelFile 1");
      // const compressed = new Uint8Array(buffer);
      // console.log("oooo --- processTranslationPayloads processing modelFile 2", compressed.length);
      // const decompressed = fzstd.decompress(compressed);
      // console.log("oooo --- processTranslationPayloads processing modelFile 3");
      // filesOut[type] = { ...file, buffer };
    }
    result.push({
      ...payload,
      languageModelFiles: filesOut,
    });
    console.log("iiiii processTranslationPayloads --- done and now waiting ???");
    // // Yield to event loop to avoid blocking ???????
    // await new Promise(resolve => setTimeout(resolve, 1000));
  }
  return result;
};

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