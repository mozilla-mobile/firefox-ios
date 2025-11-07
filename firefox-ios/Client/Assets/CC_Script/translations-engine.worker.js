/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

/**
 * @typedef {import("../translations").Bergamot} Bergamot
 * @typedef {import("../translations").TranslationModelPayload} TranslationModelPayload
 * @typedef {import("../translations").LanguageTranslationModelFiles} LanguageTranslationModelFiles
 */

/* global loadBergamot */
importScripts("chrome://global/content/translations/bergamot-translator.js");

// Respect the preference "browser.translations.logLevel".
let _loggingLevel = "Error";
function log(...args) {
  if (_loggingLevel !== "Error" && _loggingLevel !== "Warn") {
    console.log("Translations:", ...args);
  }
}
function trace(...args) {
  if (_loggingLevel === "Trace" || _loggingLevel === "All") {
    console.log("Translations:", ...args);
  }
}

// Throw Promise rejection errors so that they are visible in the console.
self.addEventListener("unhandledrejection", event => {
  throw event.reason;
});

/**
 * The alignment for each file type, file type strings should be same as in the
 * model registry.
 */
const MODEL_FILE_ALIGNMENTS = {
  model: 256,
  lex: 64,
  vocab: 64,
  qualityModel: 64,
  srcvocab: 64,
  trgvocab: 64,
};

/**
 * This regex matches the whitespace before and after a text, so that it is preserved.
 */
const WHITESPACE_REGEX = /^(\s*)(.*?)(\s*)$/s;
//                                         /s  Include newlines in .*
//                         (^^^)     (^^^)     Match the whitespace at the beginning and end.
//                              (^^^)          Non-greedily match the text (including newlines).

/**
 * At the time of writing, the Intl.Segmenter has a less-than-ideal segmentation pattern when
 * a Left Double Quotation Mark (U+201C) is preceded by a full-width punctuation mark, in which
 * it fails to segment the quotation mark with the sentence it logically belongs to.
 *
 * Example Source Text:
 *   - 这是第一句话。“这是第二句话。”
 *
 * Expected Segmentation:
 *   - Object { index: 0, segment: 这是第一句话。 }
 *   - Object { index: 7, segment: “这是第二句话。” }
 *
 * Actual Segmentation:
 *   - Object { index: 0, segment: 这是第一句话。“ }
 *   - Object { index: 8, segment: 这是第二句话。” }
 *
 * By inserting a space between the full-width punctuation and the Left Double Quotation Mark,
 * we can trick the segmenter into breaking the sentence at the correct location.
 *
 * This code may be able to be removed with further upstream improvements to Intl.Segmenter.
 * https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Segmenter
 */
const FULL_WIDTH_PUNCTUATION_REGEX = /([。！？])“/g;

/**
 * A list of languages that utilize full-width punctuation as described by the regex above.
 * https://www.unicode.org/charts/PDF/U3000.pdf
 *
 * @see {FULL_WIDTH_PUNCTUATION_REGEX}
 */
const FULL_WIDTH_PUNCTUATION_LANGUAGE_TAGS = ["ja", "ko", "zh"];

/**
 * Do any cleaning steps for the text that are required before sending it into
 * the translation engine.
 *
 * @param {string} sourceLanguage - The BCP-47 language tag for the source language.
 * @param {string} sourceText - The source text to be cleaned.
 * @returns {{ whitespaceBefore: string, whitespaceAfter: string, cleanedSourceText: string }}
 */
function cleanText(sourceLanguage, sourceText) {
  // Whitespace at the beginning or end can confuse translations, but can affect the
  // presentation of the final result.
  const result = WHITESPACE_REGEX.exec(sourceText);
  if (!result) {
    throw new Error("The whitespace regex should always return a result.");
  }
  const whitespaceBefore = result[1];
  const whitespaceAfter = result[3];
  let cleanedSourceText = result[2];

  // Remove any soft hyphens, as they will break tokenization.
  cleanedSourceText = cleanedSourceText.replaceAll("\u00AD", "");

  if (FULL_WIDTH_PUNCTUATION_LANGUAGE_TAGS.includes(sourceLanguage)) {
    // Add a space to full-width punctuation when it precedes a Left Double Quotation Mark
    // (U+201C) to trick the Intl.Segmenter algorithm into breaking a sentence there.
    /** @see {FULL_WIDTH_PUNCTUATION_REGEX} for a detailed description. */
    cleanedSourceText = cleanedSourceText.replaceAll(
      FULL_WIDTH_PUNCTUATION_REGEX,
      "$1 “"
    );
  }

  return { whitespaceBefore, whitespaceAfter, cleanedSourceText };
}

/**
 * Initialize the engine, and get it ready to handle translation requests.
 * The "initialize" message must be received before any other message handling
 * requests will be processed.
 */
addEventListener("message", handleInitializationMessage);

async function handleInitializationMessage({ data }) {
  const startTime = ChromeUtils.now();
  if (data.type !== "initialize") {
    console.error(
      "The TranslationEngine worker received a message before it was initialized."
    );
    return;
  }

  try {
    const {
      sourceLanguage,
      targetLanguage,
      enginePayload,
      logLevel,
      innerWindowId,
    } = data;

    if (!sourceLanguage) {
      throw new Error('Worker initialization missing "sourceLanguage"');
    }
    if (!targetLanguage) {
      throw new Error('Worker initialization missing "targetLanguage"');
    }

    if (logLevel) {
      // Respect the "browser.translations.logLevel" preference.
      _loggingLevel = logLevel;
    }

    let engine;
    if (enginePayload.isMocked) {
      // The engine is testing mode, and no Bergamot wasm is available.
      engine = new MockedEngine(sourceLanguage, targetLanguage);
    } else {
      const { bergamotWasmArrayBuffer, translationModelPayloads } =
        enginePayload;
      const bergamot = await BergamotUtils.initializeWasm(
        bergamotWasmArrayBuffer
      );
      engine = new Engine(
        sourceLanguage,
        targetLanguage,
        bergamot,
        translationModelPayloads
      );

      // Ensure that no memory is leaked by transfering the ArrayBuffers. They should
      // all be loaded into Wasm memory at this time. The emscripten generated code
      // appears to retain the Wasm ArrayBuffer. The transfer creates a new JS object
      // that gains ownership of the original buffer, allowing it to be GCed even
      // if the original ArrayBuffer object is retained.
      //
      // There is no evidence the language model files are retained, but this will
      // absolutely ensure we don't leak this large files.
      bergamotWasmArrayBuffer.transfer();
      for (const { languageModelFiles } of translationModelPayloads) {
        for (const file of Object.values(languageModelFiles)) {
          file.buffer.transfer();
        }
      }
    }

    ChromeUtils.addProfilerMarker(
      "TranslationsWorker",
      { startTime, innerWindowId },
      "Translations engine loaded."
    );

    handleMessages(engine);
    postMessage({ type: "initialization-success" });
  } catch (error) {
    console.error(error);
    postMessage({ type: "initialization-error", error: error?.message });
  }

  removeEventListener("message", handleInitializationMessage);
}

/**
 * Sets up the message handling for the worker.
 *
 * @param {Engine | MockedEngine} engine
 */
function handleMessages(engine) {
  let discardPromise;
  addEventListener("message", async ({ data }) => {
    try {
      if (data.type === "initialize") {
        throw new Error("The Translations engine must not be re-initialized.");
      }
      if (data.type === "translation-request") {
        // Only show these messages when "All" logging is on, since there are so many
        // of them.
        trace("Received message", data);
      } else {
        log("Received message", data);
      }

      switch (data.type) {
        case "translation-request": {
          const {
            sourceText,
            messageId,
            translationId,
            isHTML,
            innerWindowId,
          } = data;
          if (discardPromise) {
            // Wait for messages to be discarded if there are any.
            await discardPromise;
          }
          try {
            const { whitespaceBefore, whitespaceAfter, cleanedSourceText } =
              cleanText(engine.sourceLanguage, sourceText);

            // Add a translation to the work queue, and when it returns, post the message
            // back. The translation may never return if the translations are discarded
            // before it have time to be run. In this case this await is just never
            // resolved, and the postMessage is never run.
            let { targetText, inferenceMilliseconds } = await engine.translate(
              cleanedSourceText,
              isHTML,
              innerWindowId,
              translationId
            );

            // Ensure the whitespace is retained.
            targetText = whitespaceBefore + targetText + whitespaceAfter;

            // This logging level can be very verbose and slow, so only do it under the
            // "Trace" level, which is the most verbose. Set the logging level to "Info" to avoid
            // these, and get all of the other logs.
            trace("Translation complete", {
              sourceText,
              targetText,
              isHTML,
              innerWindowId,
            });

            postMessage({
              type: "translation-response",
              targetText,
              inferenceMilliseconds,
              translationId,
              messageId,
            });
          } catch (error) {
            console.error(error);
            let message = "An error occurred in the engine worker.";
            if (typeof error?.message === "string") {
              message = error.message;
            }
            let stack = "(no stack)";
            if (typeof error?.stack === "string") {
              stack = error.stack;
            }
            postMessage({
              type: "translation-error",
              error: { message, stack },
              messageId,
              innerWindowId,
            });
          }
          break;
        }
        case "discard-translation-queue": {
          ChromeUtils.addProfilerMarker(
            "TranslationsWorker",
            { innerWindowId: data.innerWindowId },
            "Translations discard requested"
          );

          discardPromise = engine.discardTranslations(data.innerWindowId);
          await discardPromise;
          discardPromise = null;

          // Signal to the "message" listeners in the main thread to stop listening.
          postMessage({
            type: "translations-discarded",
          });
          break;
        }
        case "cancel-single-translation": {
          engine.discardSingleTranslation(
            data.innerWindowId,
            data.translationId
          );
          break;
        }
        default:
          console.warn("Unknown message type:", data.type);
      }
    } catch (error) {
      // Ensure the unexpected errors are surfaced in the console.
      console.error(error);
    }
  });
}

/**
 * The Engine is created once for a language pair. The initialization process copies the
 * ArrayBuffers for the language buffers from JS-managed ArrayBuffers, to aligned
 * internal memory for the wasm heap.
 *
 * After this the ArrayBuffers are discarded and GC'd. This file should be managed
 * from the TranslationsEngine class on the main thread.
 *
 * This class starts listening for messages only after the Bergamot engine has been
 * fully initialized.
 */
class Engine {
  /**
   * @param {string} sourceLanguage
   * @param {string} targetLanguage
   * @param {Bergamot} bergamot
   * @param {Array<TranslationModelPayload>} translationModelPayloads
   */
  constructor(
    sourceLanguage,
    targetLanguage,
    bergamot,
    translationModelPayloads
  ) {
    /** @type {string} */
    this.sourceLanguage = sourceLanguage;
    /** @type {string} */
    this.targetLanguage = targetLanguage;
    /** @type {Bergamot} */
    this.bergamot = bergamot;
    /** @type {Bergamot["TranslationModel"][]} */
    this.languageTranslationModels = translationModelPayloads.map(
      translationModelPayload =>
        BergamotUtils.constructSingleTranslationModel(
          bergamot,
          translationModelPayload
        )
    );

    /** @type {Bergamot["BlockingService"]} */
    this.translationService = new bergamot.BlockingService({
      // Caching is disabled (see https://github.com/mozilla/firefox-translations/issues/288)
      cacheSize: 0,
    });
  }

  /**
   * Run the translation models to perform a batch of message translations. The
   * promise is rejected when the sync version of this function throws an error.
   * This function creates an async interface over the synchronous translation
   * mechanism. This allows other microtasks such as message handling to still work
   * even though the translations are CPU-intensive.
   *
   * @param {string} sourceText
   * @param {boolean} isHTML
   * @param {number} innerWindowId - This is required
   * @param {number} translationId
   *
   * @returns {Promise<{ targetText: string, inferenceMilliseconds: number }>}
   *   Resolves with an object containing the translated text and the inference time in ms.
   */
  translate(sourceText, isHTML, innerWindowId, translationId) {
    return this.#getWorkQueue(innerWindowId).runTask(translationId, () =>
      this.#syncTranslate(sourceText, isHTML, innerWindowId)
    );
  }

  /**
   * Map each innerWindowId to its own WorkQueue. This makes it easy to shut down
   * an entire queue of work when the page is unloaded.
   *
   * @type {Map<number, WorkQueue>}
   */
  #workQueues = new Map();

  /**
   * Get or create a `WorkQueue` that is unique to an `innerWindowId`.
   *
   * @param {number} innerWindowId
   * @returns {WorkQueue}
   */
  #getWorkQueue(innerWindowId) {
    let workQueue = this.#workQueues.get(innerWindowId);
    if (workQueue) {
      return workQueue;
    }
    workQueue = new WorkQueue(innerWindowId);
    this.#workQueues.set(innerWindowId, workQueue);
    return workQueue;
  }

  /**
   * Cancels any in-progress translations by removing the work queue.
   *
   * @param {number} innerWindowId
   */
  discardTranslations(innerWindowId) {
    let workQueue = this.#workQueues.get(innerWindowId);
    if (workQueue) {
      workQueue.cancelWork();
      this.#workQueues.delete(innerWindowId);
    }
  }

  /**
   * Cancels any in-progress translations by removing the work queue.
   *
   * @param {number} innerWindowId
   * @param {number} translationId
   */
  discardSingleTranslation(innerWindowId, translationId) {
    const workQueue = this.#workQueues.get(innerWindowId);
    if (workQueue) {
      trace("Discarding translation with translationId", translationId);
      workQueue.cancelTask(translationId);
    }
  }

  /**
   * Run the translation models to perform a translation. This
   * blocks the worker thread until it is completed.
   *
   * @param {string} sourceText
   * @param {boolean} isHTML
   * @param {number} innerWindowId
   * @returns {{ targetText: string, inferenceMilliseconds: number }}
   *   An object containing the translated text and the inference time (in ms).
   */
  #syncTranslate(sourceText, isHTML, innerWindowId) {
    const startTime = ChromeUtils.now();
    let response;
    const { messages, options } = BergamotUtils.getTranslationArgs(
      this.bergamot,
      sourceText,
      isHTML
    );
    try {
      if (messages.size() === 0) {
        return [];
      }

      /** @type {Bergamot["VectorResponse"]} */
      let responses;

      if (this.languageTranslationModels.length === 1) {
        responses = this.translationService.translate(
          this.languageTranslationModels[0],
          messages,
          options
        );
      } else if (this.languageTranslationModels.length === 2) {
        responses = this.translationService.translateViaPivoting(
          this.languageTranslationModels[0],
          this.languageTranslationModels[1],
          messages,
          options
        );
      } else {
        throw new Error(
          "Too many models were provided to the translation worker."
        );
      }

      // Report on the time it took to do this translation.
      ChromeUtils.addProfilerMarker(
        "TranslationsWorker",
        { startTime, innerWindowId },
        `Translated ${sourceText.length} code units.`
      );

      const endTime = ChromeUtils.now();
      const targetText = responses.get(0).getTranslatedText();
      return { targetText, inferenceMilliseconds: endTime - startTime };
    } finally {
      // Free up any memory that was allocated. This will always run.
      messages?.delete();
      options?.delete();
      response?.delete();
    }
  }
}

/**
 * Static utilities to help work with the Bergamot wasm module.
 */
class BergamotUtils {
  /**
   * Construct a single translation model.
   *
   * @param {Bergamot} bergamot
   * @param {TranslationModelPayload} translationModelPayload
   * @returns {Bergamot["TranslationModel"]}
   */
  static constructSingleTranslationModel(bergamot, translationModelPayload) {
    log(`Constructing translation model.`);
    const { sourceLanguage, targetLanguage, languageModelFiles } =
      translationModelPayload;

    const { model, lex, vocab, qualityModel, srcvocab, trgvocab } =
      BergamotUtils.allocateModelMemory(bergamot, languageModelFiles);

    // Transform the bytes to mb, like "10.2mb"
    const getMemory = memory => `${Math.floor(memory.size() / 100_000) / 10}mb`;

    let memoryLog = `Model memory sizes in wasm heap:`;
    memoryLog += `\n  Model: ${getMemory(model)}`;

    if (lex) {
      memoryLog += `\n  Shortlist: ${getMemory(lex)}`;
    }

    // Set up the vocab list, which could either be a single "vocab" model, or a
    // "srcvocab" and "trgvocab" pair.
    const vocabList = new bergamot.AlignedMemoryList();

    if (vocab) {
      vocabList.push_back(vocab);
      memoryLog += `\n  Vocab: ${getMemory(vocab)}`;
    } else if (srcvocab && trgvocab) {
      vocabList.push_back(srcvocab);
      vocabList.push_back(trgvocab);
      memoryLog += `\n  Src Vocab: ${getMemory(srcvocab)}`;
      memoryLog += `\n  Trg Vocab: ${getMemory(trgvocab)}`;
    } else {
      throw new Error("Vocabulary key is not found.");
    }

    if (qualityModel) {
      memoryLog += `\n  QualityModel: ${getMemory(qualityModel)}\n`;
    }

    const config = BergamotUtils.generateTextConfig({
      "beam-size": "1",
      normalize: "1.0",
      "word-penalty": "0",
      "max-length-break": "128",
      "mini-batch-words": "1024",
      workspace: "128",
      "max-length-factor": "2.0",
      "skip-cost": (!qualityModel).toString(),
      "cpu-threads": "0",
      quiet: "true",
      "quiet-translation": "true",
      "gemm-precision": languageModelFiles.model.record.name.endsWith(
        "intgemm8.bin"
      )
        ? "int8shiftAll"
        : "int8shiftAlphaAll",
      alignment: "soft",
    });

    log(`Bergamot translation model config: ${config}`);
    log(memoryLog);

    return new bergamot.TranslationModel(
      sourceLanguage,
      targetLanguage,
      config,
      model,
      lex ?? null,
      vocabList,
      qualityModel ?? null
    );
  }

  /**
   * The models must be placed in aligned memory that the Bergamot wasm module has access
   * to. This function copies over the model blobs into this memory space.
   *
   * @param {Bergamot} bergamot
   * @param {LanguageTranslationModelFiles} languageModelFiles
   * @returns {LanguageTranslationModelFilesAligned}
   */
  static allocateModelMemory(bergamot, languageModelFiles) {
    /** @type {LanguageTranslationModelFilesAligned} */
    const results = {};

    for (const [fileType, file] of Object.entries(languageModelFiles)) {
      const alignment = MODEL_FILE_ALIGNMENTS[fileType];
      if (!alignment) {
        throw new Error(`Unknown file type: "${fileType}"`);
      }

      const alignedMemory = new bergamot.AlignedMemory(
        file.buffer.byteLength,
        alignment
      );

      alignedMemory.getByteArrayView().set(new Uint8Array(file.buffer));

      results[fileType] = alignedMemory;
    }

    return results;
  }

  /**
   * Initialize the Bergamot translation engine. It is a wasm compiled version of the
   * Marian translation software. The wasm is delivered remotely to cut down on binary size.
   *
   * https://github.com/mozilla/bergamot-translator/
   *
   * @param {ArrayBuffer} wasmBinary
   * @returns {Promise<Bergamot>}
   */
  static initializeWasm(wasmBinary) {
    return new Promise((resolve, reject) => {
      /** @type {number} */
      let start = performance.now();

      /** @type {Bergamot} */
      const bergamot = loadBergamot({
        // Start with 40MiB initial memory. This value is arbitrary, but we have observed
        // through performance testing that starting small and allowing the buffer to grow
        // results in less memory usage than unintentionally overshooting the initial allocation.
        INITIAL_MEMORY: 41_943_040,
        print: log,
        onAbort() {
          reject(new Error("Error loading Bergamot wasm module."));
        },
        onRuntimeInitialized: async () => {
          const duration = performance.now() - start;
          log(
            `Bergamot wasm runtime initialized in ${duration / 1000} seconds.`
          );
          // Await at least one microtask so that the captured `bergamot` variable is
          // fully initialized.
          await Promise.resolve();
          resolve(bergamot);
        },
        wasmBinary,
      });
    });
  }

  /**
   * Maps the Bergamot Vector to a JS array
   *
   * @param {Bergamot["Vector"]} vector
   * @param {Function} fn
   * @returns {Array}
   */
  static mapVector(vector, fn) {
    const result = [];
    for (let index = 0; index < vector.size(); index++) {
      result.push(fn(vector.get(index), index));
    }
    return result;
  }

  /**
   * Generate a config for the Marian translation service. It requires specific whitespace.
   *
   * https://marian-nmt.github.io/docs/cmd/marian-decoder/
   *
   * @param {Record<string, string>} config
   * @returns {string}
   */
  static generateTextConfig(config) {
    const indent = "            ";
    let result = "\n";

    for (const [key, value] of Object.entries(config)) {
      result += `${indent}${key}: ${value}\n`;
    }

    return result + indent;
  }

  /**
   * JS objects need to be translated into wasm objects to configure the translation engine.
   *
   * @param {Bergamot} bergamot
   * @param {string} sourceText
   * @param {boolean} isHTML
   * @returns {{ messages: Bergamot["VectorString"], options: Bergamot["VectorResponseOptions"] }}
   */
  static getTranslationArgs(bergamot, sourceText, isHTML) {
    const messages = new bergamot.VectorString();
    const options = new bergamot.VectorResponseOptions();

    // Empty paragraphs break the translation.
    if (sourceText) {
      messages.push_back(sourceText);
      options.push_back({
        qualityScores: false,
        alignment: true,
        html: isHTML,
      });
    }

    return { messages, options };
  }
}

/**
 * For testing purposes, provide a fully mocked engine. This allows for easy integration
 * testing of the UI, without having to rely on downloading remote models and remote
 * wasm binaries.
 */
class MockedEngine {
  /**
   * @param {string} sourceLanguage
   * @param {string} targetLanguage
   */
  constructor(sourceLanguage, targetLanguage) {
    /** @type {string} */
    this.sourceLanguage = sourceLanguage;
    /** @type {string} */
    this.targetLanguage = targetLanguage;
  }

  /**
   * Create a fake translation of the text, returning a mock object
   * with both the translated text and time spent.
   *
   * @param {string} sourceText
   * @param {boolean} isHTML
   * @returns {{ targetText: string, inferenceMilliseconds: number }}
   *   An object containing the "translated" text and a mock inference time in ms.
   */
  translate(sourceText, isHTML) {
    const startTime = performance.now();

    // Note when an HTML translation is requested.
    let html = isHTML ? ", html" : "";
    const targetText = `${sourceText.toUpperCase()} [${this.sourceLanguage} to ${this.targetLanguage}${html}]`;
    const endTime = performance.now();

    return { targetText, inferenceMilliseconds: endTime - startTime };
  }

  discardTranslations() {}
}

/**
 * This class takes tasks that may block the thread's event loop, and has them yield
 * after a time budget via setTimeout calls to allow other code to execute.
 */
class WorkQueue {
  #TIME_BUDGET = 100; // ms
  #RUN_IMMEDIATELY_COUNT = 20;

  /**
   * This is the list of work to be done. While it is a Map, it is treated as a FIFO
   * queue, but with work that can be canceled via the translationId.
   *
   * @type {Map<number, {task: Function, resolve: Function}>}
   */
  #tasksByTranslationId = new Map();
  #isRunning = false;
  #isWorkCancelled = false;
  #runImmediately = this.#RUN_IMMEDIATELY_COUNT;

  /**
   * @param {number} innerWindowId
   */
  constructor(innerWindowId) {
    this.innerWindowId = innerWindowId;
  }

  /**
   * Run the task and return the result.
   *
   * @template {any} T
   * @param {number} translationId
   * @param {() => T} task
   * @returns {Promise<T>}
   */
  runTask(translationId, task) {
    if (this.#runImmediately > 0) {
      // Run the first N translations immediately, most likely these are the user-visible
      // translations on the page, as they are sent in first. The setTimeout of 0 can
      // still delay the translations noticeably.
      this.#runImmediately--;
      return Promise.resolve(task());
    }
    return new Promise((resolve, reject) => {
      this.#tasksByTranslationId.set(translationId, { task, resolve, reject });
      this.#run().catch(error => console.error(error));
    });
  }

  /**
   * @param {number} translationId
   */
  cancelTask(translationId) {
    this.#tasksByTranslationId.delete(translationId);
  }

  /**
   * The internal run function.
   */
  async #run() {
    if (this.#isRunning) {
      // The work queue is already running.
      return;
    }

    this.#isRunning = true;

    // Measure the timeout
    let lastTimeout = null;

    let tasksInBatch = 0;
    const addProfilerMarker = () => {
      ChromeUtils.addProfilerMarker(
        "TranslationsWorker WorkQueue",
        { startTime: lastTimeout, innerWindowId: this.innerWindowId },
        `WorkQueue processed ${tasksInBatch} tasks`
      );
    };

    while (this.#tasksByTranslationId.size) {
      if (this.#isWorkCancelled) {
        // The work was already cancelled.
        break;
      }
      const now = ChromeUtils.now();

      if (lastTimeout === null) {
        lastTimeout = now;
        // Allow other work to get on the queue.
        await new Promise(resolve => setTimeout(resolve, 0));
      } else if (now - lastTimeout > this.#TIME_BUDGET) {
        // Perform a timeout with no effective wait. This clears the current
        // promise queue from the event loop.
        await new Promise(resolve => setTimeout(resolve, 0));
        addProfilerMarker();
        lastTimeout = ChromeUtils.now();
      }

      // Check this between every `await`.
      if (this.#isWorkCancelled || !this.#tasksByTranslationId.size) {
        break;
      }

      tasksInBatch++;

      // Treat the `this.#tasksByTranslationId` Map as a FIFO queue, and take the oldest
      // item out by manually using the `entries()` iterator.
      const [translationId, taskAndResolvers] = this.#tasksByTranslationId
        .entries()
        .next().value;
      const { task, resolve, reject } = taskAndResolvers;
      this.#tasksByTranslationId.delete(translationId);

      try {
        const result = await task();

        // Check this between every `await`.
        if (this.#isWorkCancelled) {
          break;
        }
        // The work is done, resolve the original task.
        resolve(result);
      } catch (error) {
        reject(error);
      }
    }
    addProfilerMarker();
    this.#isRunning = false;
  }

  async cancelWork() {
    this.#isWorkCancelled = true;
    this.#tasksByTranslationId = new Map();
    await new Promise(resolve => setTimeout(resolve, 0));
    this.#isWorkCancelled = false;
  }
}
