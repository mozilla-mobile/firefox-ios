import "resource://gre/modules/shared/TranslationsHelpers.ios.mjs";

import { getLanguageSampleWhenReady } from "./LanguageSampleExtractor.js";
import { LRUCache, TranslationsDocument } from "Assets/CC_Script/translations-document.sys.mjs";
import "Assets/CC_Script/translations-engine.sys.mjs";


const { port1, port2 } = new MessageChannel();
const innerWindowId = crypto.randomUUID();

const sendToEngine = (message) => {
    window.webkit.messageHandlers.left.postMessage({...message, channelId: innerWindowId});
}

window.receive = (message) => {
    console.log("[dbg][issam][TranslationsEntrypoint.js] receive from engine:", message);
    /// TODO(Issam): Engine ends after like 15 seconds. But it's weird how we establish connection.
    // For now, we just ignore this and rely on the message channel.
    if(message.type !== "TranslationsPort:EngineTerminated") {
        port1.postMessage(message);
    }
};

port1.onmessage = (message) => {
    const payload = message.data;
    // TODO(Issam): Add docs at top of this function explaining flow of data.
    sendToEngine(payload);
};

const startEverything = ({from, to}) => {
    console.log("[dbg][issam][TranslationsEntrypoint.js] startEverything:", {from, to, innerWindowId});
    const languagePair = {sourceLanguage: from, targetLanguage: to}
    const translationsCache = new LRUCache(languagePair);
    const translatedDoc = new TranslationsDocument(
        document,
        from,
        to,
        innerWindowId,
        port2,
        () => console.log("[dbg][issam][TranslationsEntrypoint.js] ---- foooo 1"),
        () => console.log("[dbg][issam][TranslationsEntrypoint.js] ---- foooo 2"),
        translationsCache,
    );

    const message = {
        type: "StartTranslation",
        languagePair,
        innerWindowId,
        // NOTE(Issam): We can't serialize this for now and webkit postMessage has no transferables
        // Which is why we have to do the little dance with the webview bridge.
        // port: port1,
    };
    sendToEngine(message);
};

const discardTranslations = ({from, to}) => {
    sendToEngine({ type: "DiscardTranslations", innerWindowId })
};

// TODO(Issam): Just mock for now to unblock UI. 
// This should be properly implemented later but the calling code shouldn't care.
const isDone = async () => {
  await new Promise(resolve => setTimeout(resolve, 3000));
  return true;
};

Object.defineProperty(window.__firefox__, "Translations", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: Object.freeze({ getLanguageSampleWhenReady, startEverything, isDone, discardTranslations })
});