/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * This file lives in the translation engine's process and is in charge of managing the
 * lifecycle of the translations engines. This process is a singleton Web Content
 * process that can be created and destroyed as needed.
 *
 * The goal of the code in this file is to be as unprivileged as possible, which should
 * unlock Bug 1813789, which will make this file fully unprivileged.
 *
 * Each translation needs an engine for that specific language pair. This engine is
 * kept around as long as the CACHE_TIMEOUT_MS, after this if some keepAlive event does
 * not happen, the engine is destroyed. An engine may be destroyed even when a page is
 * still open and may need translations in the future. This is handled gracefully by
 * creating new engines and MessagePorts on the fly.
 *
 * The engine communicates directly with the content page via a MessagePort. Each end
 * of the port is transferred from the parent process to the content process, and this
 * engine process. This port is transitory, and may be closed at any time. Only when a
 * translation has been requested once (which is initiated by the parent process) can
 * the content process re-request translation ports. This ensures a rogue content process
 * only has the capabilities to perform tasks that the parent process has given it.
 *
 * The messaging flow can get a little convoluted to handle all of the correctness cases,
 * but ideally communication passes through the message port as much as possible. There
 * are many scenarios such as:
 *
 *  - Translation pages becoming idle
 *  - Tab changing causing "pageshow" and "pagehide" visibility changes
 *  - Translation actor destruction (this can happen long after the page has been
 *                                   navigated away from, but is still alive in the
 *                                   page history)
 *  - Error states
 *  - Engine Process being graceful shut down (no engines left)
 *  - Engine Process being killed by the OS.
 *
 * The following is a diagram that attempts to illustrate the structure of the processes
 * and the communication channels that exist between them.
 *
 * ┌─────────────────────────────────────────────────────────────┐
 * │ PARENT PROCESS                                              │
 * │                                                             │
 * │  [TranslationsParent]  ←────→  [TranslationsEngineParent]   │
 * │                  ↑                                    ↑     │
 * └──────────────────│────────────────────────────────────│─────┘
 *                    │ JSWindowActor IPC calls            │ JSProcessActor IPC calls
 *                    │                                    │
 * ┌──────────────────│────────┐                     ┌─────│─────────────────────────────┐
 * │ CONTENT PROCESS  │        │                     │     │    ENGINE PROCESS           │
 * │                  │        │                     │     ↓                             │
 * │  [french.html]   │        │                     │ [TranslationsEngineChild]         │
 * │        ↕         ↓        │                     │            ↕                      │
 * │  [TranslationsChild]      │                     │ [translations-engine.sys.mjs]     │
 * │  └──TranslationsDocument  │                     │    ├── "fr to en" engine          │
 * │     └──port1     « ═══════════ MessageChannel ════ » │   └── port2                  │
 * │                           │                     │    └── "de to en" engine (idle)   │
 * └───────────────────────────┘                     └───────────────────────────────────┘
 */

// FIXME: Currently, `translations-engine.sys.mjs` is loaded with the system
// principal within the sys.mjs context.
//
// There is some existing code which exported these methods in a global scope
// from when this file was being loaded within a chrome .html document within
// the content process, however this code no longer exists.
//
// This block re-exports various methods from the singleton TranslationsEngine
// actor into this scope so they can be called as they were called before the
// change to use a ProcessActor.
//
// In the future, this code could perhaps be modified to run within an
// unprivileged Cu.Sandbox, with these specific methods re-exported into the
// sandbox scope.

const engineActor = ChromeUtils.domProcessChild.getActor("TranslationsEngine");

const TE_addProfilerMarker = engineActor.TE_addProfilerMarker.bind(engineActor);
const TE_getLogLevel = engineActor.TE_getLogLevel.bind(engineActor);
const TE_log = engineActor.TE_log.bind(engineActor);
const TE_logError = engineActor.TE_logError.bind(engineActor);
const TE_requestEnginePayload =
  engineActor.TE_requestEnginePayload.bind(engineActor);
const TE_reportEnginePerformance =
  engineActor.TE_reportEnginePerformance.bind(engineActor);
const TE_reportEngineStatus =
  engineActor.TE_reportEngineStatus.bind(engineActor);
const TE_resolveForceShutdown =
  engineActor.TE_resolveForceShutdown.bind(engineActor);
const TE_destroyEngineProcess =
  engineActor.TE_destroyEngineProcess.bind(engineActor);

// How long the cache remains alive between uses, in milliseconds. In automation the
// engine is manually created and destroyed to avoid timing issues.
const CACHE_TIMEOUT_MS = 15_000;

/**
 * @typedef {import("./translations-document.sys.mjs").TranslationsDocument} TranslationsDocument
 * @typedef {import("../translations.js").TranslationsEnginePayload} TranslationsEnginePayload
 * @typedef {import("../translations.js").LanguagePair} LanguagePair
 */

const lazy = {};
ChromeUtils.defineESModuleGetters(lazy, {
  clearTimeout: "resource://gre/modules/Timer.sys.mjs",
  setTimeout: "resource://gre/modules/Timer.sys.mjs",
  TranslationsUtils:
    "chrome://global/content/translations/TranslationsUtils.mjs",
});

/**
 * The TranslationsEngine encapsulates the logic for translating messages. It can
 * only be set up for a single language pair. In order to change languages
 * a new engine should be constructed.
 *
 * The actual work for the translations happens in a worker. This class manages
 * instantiating and messaging the worker.
 *
 * Keep unused engines around in the TranslationsEngine.#cachedEngine cache in case
 * page navigation happens and we can re-use previous engines. The engines are very
 * heavy-weight, so get rid of them after a timeout. Once all are destroyed the
 * TranslationsEngineParent is notified that it can be destroyed.
 */
export class TranslationsEngine {
  /**
   * Maps a language pair key to a cached engine. Engines are kept around for a timeout
   * before they are removed so that they can be re-used during navigation.
   *
   * @type {Map<string, Promise<TranslationsEngine>>}
   */
  static #cachedEngines = new Map();

  /**
   * A DOMParser instance used for parsing HTML strings into DOM objects.
   *
   * @type {DOMParser}
   */
  static #domParser = new DOMParser();

  /**
   * The ID of a timer that keeps the engine alive in the cache.
   *
   * @see {#cachedEngines}
   *
   * @type {TimeoutID | null}
   */
  #keepAliveTimeout = null;

  /**
   * The Web Worker instance used to handle translation requests.
   *
   * @type {Worker}
   */
  #worker;

  /**
   * Multiple messages can be sent before a response is received. This ID is used to keep
   * track of the messages. It is incremented on every use.
   *
   * @type {number}
   */
  #messageId = 0;

  /**
   * The total count of completed translation requests.
   *
   * @type {number}
   */
  #totalCompletedRequests = 0;

  /**
   * The total count of words translated across all requests.
   *
   * @type {number}
   */
  #totalTranslatedWords = 0;

  /**
   * The total milliseconds spent in active translation inference.
   *
   * @type {number}
   */
  #totalInferenceMilliseconds = 0;

  /**
   * A word segmenter instance corresponding to the language of the source text.
   *
   * @type {Intl.Segmenter | null}
   */
  #wordSegmenter = null;

  /**
   * Returns a getter function that will create a translations engine on the first
   * call, and then return the cached one. After a timeout when the engine hasn't
   * been used, it is destroyed.
   *
   * @param {LanguagePair} languagePair
   * @param {number} innerWindowId
   * @returns {Promise<TranslationsEngine>}
   */
  static getOrCreate(languagePair, innerWindowId) {
    const languagePairKey =
      lazy.TranslationsUtils.serializeLanguagePair(languagePair);
    let enginePromise = TranslationsEngine.#cachedEngines.get(languagePairKey);

    if (enginePromise) {
      return enginePromise;
    }

    TE_log(`Creating a new engine for "${languagePairKey}".`);

    // A new engine needs to be created.
    enginePromise = TranslationsEngine.create(languagePair, innerWindowId);

    TranslationsEngine.#cachedEngines.set(languagePairKey, enginePromise);

    enginePromise.catch(error => {
      TE_logError(
        `The engine failed to load for translating "${languagePairKey}". Removing it from the cache.`,
        error
      );
      // Remove the engine if it fails to initialize.
      TranslationsEngine.#removeEngineFromCache(languagePairKey);
    });

    return enginePromise;
  }

  /**
   * Removes the engine, and if it's the last, call the process to destroy itself.
   *
   * @param {string} languagePairKey
   * @param {boolean} force - On forced shutdowns, it's not necessary to notify the
   *                          parent process.
   */
  static #removeEngineFromCache(languagePairKey, force) {
    TranslationsEngine.#cachedEngines.delete(languagePairKey);
    if (TranslationsEngine.#cachedEngines.size === 0 && !force) {
      TE_log("The last engine was removed, destroying this process.");
      TE_destroyEngineProcess();
    }
  }

  /**
   * Create a TranslationsEngine and bypass the cache.
   *
   * @param {LanguagePair} languagePair
   * @param {number} innerWindowId
   * @returns {Promise<TranslationsEngine>}
   */
  static async create(languagePair, innerWindowId) {
    const startTime = ChromeUtils.now();
    if (!languagePair.sourceLanguage || !languagePair.targetLanguage) {
      throw new Error(
        "Attempt to create Translator with missing language tags."
      );
    }

    const engine = new TranslationsEngine(
      languagePair,
      await TE_requestEnginePayload(languagePair)
    );

    await engine.isReady;

    TE_addProfilerMarker({
      startTime,
      message: `Translations engine loaded for "${lazy.TranslationsUtils.serializeLanguagePair(languagePair)}"`,
      innerWindowId,
    });

    return engine;
  }

  /**
   * Signal to the engines that they are being forced to shutdown.
   */
  static forceShutdown() {
    return Promise.allSettled(
      [...TranslationsEngine.#cachedEngines].map(
        async ([langPair, enginePromise]) => {
          TE_log(`Force shutdown of the engine "${langPair}"`);
          const engine = await enginePromise;
          engine.terminate(true /* force */);
        }
      )
    );
  }

  /**
   * Terminates the engine and its worker after a timeout.
   *
   * @param {boolean} force
   */
  terminate = (force = false) => {
    const message = `Terminating translations engine "${this.languagePairKey}".`;

    this.#maybeReportEnginePerformance();
    TE_addProfilerMarker({ message });
    TE_log(message);
    this.#worker.terminate();
    this.#worker = null;
    if (this.#keepAliveTimeout) {
      lazy.clearTimeout(this.#keepAliveTimeout);
    }
    for (const [innerWindowId, data] of ports) {
      const { sourceLanguage, targetLanguage, port } = data;
      if (
        sourceLanguage === this.sourceLanguage &&
        targetLanguage === this.targetLanguage
      ) {
        // This port is still active but being closed.
        ports.delete(innerWindowId);
        port.postMessage({ type: "TranslationsPort:EngineTerminated" });
        port.close();
      }
    }
    TranslationsEngine.#removeEngineFromCache(this.languagePairKey, force);
  };

  /**
   * The worker needs to be shutdown after some amount of time of not being used.
   */
  keepAlive() {
    if (this.#keepAliveTimeout) {
      // Clear any previous timeout.
      lazy.clearTimeout(this.#keepAliveTimeout);
    }
    // In automated tests, the engine is manually destroyed.
    if (!Cu.isInAutomation) {
      this.#keepAliveTimeout = lazy.setTimeout(
        this.terminate,
        CACHE_TIMEOUT_MS
      );
    }
  }

  /**
   * Reports this engine's performance metrics to telemetry if it
   * has completed at least one successful translation request.
   */
  #maybeReportEnginePerformance() {
    if (!this.#totalCompletedRequests) {
      // This engine did not translate any requests to completion.
      // There is nothing to report.
      return;
    }

    const { sourceLanguage, targetLanguage } = this.languagePair;

    TE_reportEnginePerformance({
      sourceLanguage,
      targetLanguage,
      totalInferenceSeconds: this.#totalInferenceMilliseconds / 1000,
      totalTranslatedWords: this.#totalTranslatedWords,
      totalCompletedRequests: this.#totalCompletedRequests,
    });
  }

  /**
   * Construct and initialize the worker.
   *
   * @param {LanguagePair} languagePair
   * @param {TranslationsEnginePayload} enginePayload - If there is no engine payload
   *   then the engine will be mocked. This allows this class to be used in tests.
   */
  constructor(languagePair, enginePayload) {
    /** @type {LanguagePair} */
    this.languagePair = languagePair;
    this.languagePairKey =
      lazy.TranslationsUtils.serializeLanguagePair(languagePair);
    this.#worker = new Worker(
      "chrome://global/content/translations/translations-engine.worker.js"
    );

    /** @type {Promise<void>} */
    this.isReady = new Promise((resolve, reject) => {
      const onMessage = ({ data }) => {
        TE_log("Received initialization message", data);
        if (data.type === "initialization-success") {
          resolve();
        } else if (data.type === "initialization-error") {
          reject(data.error);
        }
        this.#worker.removeEventListener("message", onMessage);
      };
      this.#worker.addEventListener("message", onMessage);

      try {
        this.#wordSegmenter = new Intl.Segmenter(this.sourceLanguage, {
          granularity: "word",
        });
      } catch (error) {
        reject(error);
      }

      // Schedule the first timeout for keeping the engine alive.
      this.keepAlive();
    });

    // Make sure the ArrayBuffers are transferred, not cloned.
    // https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Transferable_objects
    const transferables = [];
    if (enginePayload) {
      transferables.push(enginePayload.bergamotWasmArrayBuffer);
      for (const translationModelPayload of enginePayload.translationModelPayloads) {
        const { languageModelFiles } = translationModelPayload;
        for (const { buffer } of Object.values(languageModelFiles)) {
          transferables.push(buffer);
        }
      }
    }

    const { sourceLanguage, targetLanguage } = languagePair;

    this.#worker.postMessage(
      {
        type: "initialize",
        sourceLanguage,
        targetLanguage,
        enginePayload,
        messageId: this.#messageId++,
        logLevel: TE_getLogLevel(),
      },
      transferables
    );
  }

  /**
   * Counts the number of words in the given source text.
   *
   * @param {string} sourceText - The text to be counted.
   * @param {boolean} isHTML - Whether to parse the text as HTML.
   * @returns {number} - The total count of word-like segments in the text.
   */
  #countWords(sourceText, isHTML) {
    if (isHTML) {
      sourceText = TranslationsEngine.#domParser.parseFromString(
        sourceText,
        "text/html"
      ).documentElement.textContent;
    }

    let wordCount = 0;
    for (const { isWordLike } of this.#wordSegmenter.segment(sourceText)) {
      if (isWordLike) {
        wordCount += 1;
      }
    }

    return wordCount;
  }

  /**
   * The implementation for translation. Use translateText or translateHTML for the
   * public API.
   *
   * @param {string} sourceText
   * @param {boolean} isHTML
   * @param {number} innerWindowId
   * @param {number} translationId
   * @returns {Promise<string>}
   *   A promise that resolves with the translated text.
   */
  translate(sourceText, isHTML, innerWindowId, translationId) {
    this.keepAlive();

    const messageId = this.#messageId++;

    return new Promise((resolve, reject) => {
      const onMessage = ({ data }) => {
        if (
          data.type === "translations-discarded" &&
          data.innerWindowId === innerWindowId
        ) {
          // The page was unloaded, and we no longer need to listen for a response.
          this.#worker.removeEventListener("message", onMessage);
          return;
        }

        if (data.messageId !== messageId) {
          // Multiple translation requests can be sent before a response is received.
          // Ensure that the response received here is the correct one.
          return;
        }

        if (data.type === "translation-response") {
          // Also keep the translation alive after getting a result, as many translations
          // can queue up at once, and then it can take minutes to resolve them all.
          this.keepAlive();

          const { targetText, inferenceMilliseconds } = data;

          resolve(targetText);

          const sourceTextWordCount = this.#countWords(sourceText, isHTML);
          this.#totalInferenceMilliseconds += inferenceMilliseconds;
          this.#totalTranslatedWords += sourceTextWordCount;
          this.#totalCompletedRequests += 1;
        }
        if (data.type === "translation-error") {
          reject(data.error);
        }
        this.#worker.removeEventListener("message", onMessage);
      };

      this.#worker.addEventListener("message", onMessage);

      this.#worker.postMessage({
        type: "translation-request",
        isHTML,
        sourceText,
        messageId,
        translationId,
        innerWindowId,
      });
    });
  }

  /**
   * Applies a function only if a cached engine exists.
   *
   * @param {LanguagePair} languagePair
   * @param {(engine: TranslationsEngine) => void} fn
   */
  static withCachedEngine(languagePair, fn) {
    const engine = TranslationsEngine.#cachedEngines.get(
      lazy.TranslationsUtils.serializeLanguagePair(languagePair)
    );

    if (engine) {
      engine.then(fn).catch(() => {});
    }
  }

  /**
   * Stop processing the translation queue. All in-progress messages will be discarded.
   *
   * @param {number} innerWindowId
   */
  discardTranslationQueue(innerWindowId) {
    this.#worker.postMessage({
      type: "discard-translation-queue",
      innerWindowId,
    });
  }

  /**
   * Cancel a single translation.
   *
   * @param {number} innerWindowId
   * @param {id} translationId
   */
  cancelSingleTranslation(innerWindowId, translationId) {
    this.#worker.postMessage({
      type: "cancel-single-translation",
      innerWindowId,
      translationId,
    });
  }
}

/**
 * Maps the innerWindowId to the port.
 *
 * @type {Map<number, {
 *  languagePair: LanguagePair,
 *  port: MessagePort
 * }>}
 */
const ports = new Map();

/**
 * Listen to the port to the content process for incoming messages, and pass
 * them to the TranslationsEngine manager. The other end of the port is held
 * in the content process by the TranslationsDocument.
 *
 * @param {LanguagePair} languagePair
 * @param {number} innerWindowId
 * @param {MessagePort} port
 */
function listenForPortMessages(languagePair, innerWindowId, port) {
  async function handleMessage({ data }) {
    switch (data.type) {
      case "TranslationsPort:GetEngineStatusRequest": {
        // This message gets sent first before the translation queue is processed.
        // The engine is most likely to fail on the initial invocation. Any failure
        // past the first one is not reported to the UI.
        TranslationsEngine.getOrCreate(languagePair, innerWindowId).then(
          () => {
            TE_log("The engine is ready for translations.", {
              innerWindowId,
            });
            TE_reportEngineStatus(innerWindowId, "ready");
            port.postMessage({
              type: "TranslationsPort:GetEngineStatusResponse",
              status: "ready",
            });
          },
          error => {
            console.error(error);
            TE_reportEngineStatus(innerWindowId, "error");
            port.postMessage({
              type: "TranslationsPort:GetEngineStatusResponse",
              status: "error",
              error: String(error),
            });
            // After an error no more translation requests will be sent. Go ahead
            // and close the port.
            port.close();
            ports.delete(innerWindowId);
          }
        );
        break;
      }
      case "TranslationsPort:Passthrough": {
        const { translationId } = data;

        port.postMessage({
          type: "TranslationsPort:TranslationResponse",
          translationId,
          targetText: null,
        });

        TE_addProfilerMarker({
          innerWindowId,
          type: "Passthrough",
          message: `Handled passthrough translation`,
        });

        break;
      }
      case "TranslationsPort:CachedTranslation": {
        const { cachedTranslation, translationId } = data;
        port.postMessage({
          type: "TranslationsPort:TranslationResponse",
          translationId,
          targetText: cachedTranslation,
        });

        TE_addProfilerMarker({
          innerWindowId,
          type: "Cached",
          message: `Handled cached translation of ${cachedTranslation.length} code units`,
        });

        break;
      }
      case "TranslationsPort:TranslationRequest": {
        const { sourceText, isHTML, translationId } = data;

        const engine = await TranslationsEngine.getOrCreate(
          languagePair,
          innerWindowId
        );

        TE_addProfilerMarker({
          innerWindowId,
          type: "Request",
          message: `Handled translation request of ${sourceText.length} code units`,
        });

        const targetText = await engine.translate(
          sourceText,
          isHTML,
          innerWindowId,
          translationId
        );

        port.postMessage({
          type: "TranslationsPort:TranslationResponse",
          translationId,
          targetText,
        });

        break;
      }
      case "TranslationsPort:CancelSingleTranslation": {
        const { translationId } = data;
        TranslationsEngine.withCachedEngine(languagePair, engine => {
          engine.cancelSingleTranslation(innerWindowId, translationId);
        });

        TE_addProfilerMarker({
          innerWindowId,
          type: "Cancel",
          message: `Cancelled request for translationId ${translationId}`,
        });
        break;
      }
      case "TranslationsPort:DiscardTranslations": {
        discardTranslations(innerWindowId);
        TE_addProfilerMarker({
          innerWindowId,
          type: "Discard",
          message: `Discarded all active translation requests`,
        });
        break;
      }
      default:
        TE_logError("Unknown translations port message: " + data.type);
        break;
    }
  }

  if (port.onmessage) {
    TE_logError(
      new Error("The MessagePort onmessage handler was already present.")
    );
  }

  port.onmessage = event => {
    handleMessage(event).catch(error => TE_logError(error));
  };
}

/**
 * Discards the queue and removes the port.
 *
 * @param {number} innerWindowId
 */
function discardTranslations(innerWindowId) {
  TE_log("Discarding translations, innerWindowId:", innerWindowId);

  const portData = ports.get(innerWindowId);
  if (portData) {
    const { port, languagePair } = portData;
    port.close();
    ports.delete(innerWindowId);

    TranslationsEngine.withCachedEngine(languagePair, engine => {
      engine.discardTranslationQueue(innerWindowId);
    });
  }
}

/**
 * Listen for events coming from the TranslationsEngine actor.
 */
export function handleActorMessage(data) {
  switch (data.type) {
    case "StartTranslation": {
      const { languagePair, innerWindowId, port } = data;
      TE_log(
        "Starting translation",
        lazy.TranslationsUtils.serializeLanguagePair(languagePair),
        innerWindowId
      );
      listenForPortMessages(languagePair, innerWindowId, port);
      ports.set(innerWindowId, { port, languagePair });
      break;
    }
    case "DiscardTranslations": {
      const { innerWindowId } = data;
      discardTranslations(innerWindowId);
      break;
    }
    case "ForceShutdown": {
      TranslationsEngine.forceShutdown().then(() => {
        TE_resolveForceShutdown();
      });
      break;
    }
    default:
      throw new Error("Unknown TranslationsEngineChromeToContent event.");
  }
}
