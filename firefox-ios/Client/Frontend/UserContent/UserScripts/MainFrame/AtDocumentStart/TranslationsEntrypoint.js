import "Assets/CC_Script/TranslationsHelpers.mjs";

import { getLanguageSampleWhenReady } from "./LanguageSampleExtractor.js";
import { LRUCache, TranslationsDocument } from "Assets/CC_Script/translations-document.sys.mjs";
import "Assets/CC_Script/translations-engine.sys.mjs";


/// NOTE: Translation is a living process ( e.g live chat in twitch ) so there is no single "done" state.
/// In Gecko, we mark translations done when the engine is ready.
/// In iOS, we will go a step further and wait for the first translation response to be received.
let isDoneResolve;
let isDoneReject;
let isDonePromise;

const resetIsDone = () => {
    isDonePromise = new Promise((resolve, reject) => {
        isDoneResolve = resolve;
        isDoneReject = reject;
    });
};

resetIsDone();

/// NOTE: The way content and priviliged contexts in gecko communicate is via message channels. 
const innerWindowId = crypto.randomUUID();

let enginePort = null;
let translatedDocument = null;
let languagePair = null;

const sendToEngine = (message) => {
    window.webkit.messageHandlers.left.postMessage({...message, channelId: innerWindowId});
}

const openPortToDocument = () => {
    const { port1, port2 } = new MessageChannel();
    port1.onmessage = (message) => sendToEngine(message.data);
    enginePort = port1;
    return port2;
};

/// NOTE: This receives messages from the engine and forwards them to the content context.
/// For "done" messages, it resolves the isDone promise.
window.receive = (message) => {
    if (message.type === "TranslationsPort:TranslationResponse" && isDoneResolve) {
        isDoneResolve(true);
        isDoneResolve = null;
        isDoneReject = null;
    }

    if (message.type === "TranslationsPort:GetEngineStatusResponse" && message.status === "error" && isDoneReject) {
        isDoneReject(new Error("translation engine failed to load"));
        isDoneReject = null;
        isDoneResolve = null;
    }

    enginePort?.postMessage(message);
};

/// NOTE: The engine closes its side of the channel when it goes idle.
const requestNewPort = () => {
    if (!translatedDocument) {
        return;
    }

    /// NOTE: Order matters: `acquirePort` asks for engine status, which is dropped without a channel.
    sendToEngine({ type: "StartTranslation", languagePair, innerWindowId });
    translatedDocument.acquirePort(openPortToDocument());
};


/// NOTE: This should be called to start the translation process for this document.
/// This creates the TranslationsDocument instance that manages the translation lifecycle.
const startTranslations = ({from, to}) => {
    resetIsDone();
    languagePair = {sourceLanguage: from, targetLanguage: to}
    const translationsCache = new LRUCache(languagePair);
    translatedDocument = new TranslationsDocument(
        document,
        from,
        to,
        innerWindowId,
        openPortToDocument(),
        requestNewPort,
        () => {},
        translationsCache,
    );

    /// NOTE: In Gecko, we can transfer the port directly to the engine context.
    /// In WebKit, we have to do a dance with the webview bridge since it doesn't support transferables for ports.
    const message = {
        type: "StartTranslation",
        languagePair,
        innerWindowId,
    };
    sendToEngine(message);
};

/// NOTE: This should be called when we teardown the translations for this document.
const discardTranslations = ({from, to}) => {
    translatedDocument = null;
    languagePair = null;
    enginePort = null;
    resetIsDone();
    sendToEngine({ type: "DiscardTranslations", innerWindowId })
};

/// NOTE: This returns a promise that resolves when the translation process is "done".
/// This is used mainly to turn the translations button to the active state in the UI.
/// This should be called from swift.
// TODO: FXIOS-15246 Translation spinner gets stuck indefinitely
const TRANSLATION_TIMEOUT_MS = 15000;
const isDone = () => {
    let timeoutId;
    return Promise.race([
        isDonePromise,
        new Promise((_, reject) => {
            timeoutId = setTimeout(
                () => reject(new Error("translation timed out")),
                TRANSLATION_TIMEOUT_MS
            );
        })
    ]).finally(() => clearTimeout(timeoutId));
};

/// NOTE: Expose the Translations API to the privileged context.
/// Anything not exposed here will not be accessible outside this user script.
Object.defineProperty(window.__firefox__, "Translations", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: Object.freeze({ getLanguageSampleWhenReady, startTranslations, isDone, discardTranslations })
});