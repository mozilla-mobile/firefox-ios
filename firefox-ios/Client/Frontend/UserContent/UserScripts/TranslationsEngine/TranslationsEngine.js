import "Assets/CC_Script/TranslationsHelpers.ios.mjs";
import { handleActorMessage } from "Assets/CC_Script/translations-engine.sys.mjs";

/// TODO(Issam): We can make this a tiny lib where we import and create the bi-directional bridge for both sides.
const sendToPage = (message) => {
  console.log("[dbg][issam][TranslationsEngine.js] sending back to page:", message, window.webkit.messageHandlers.right.postMessage);
  window.webkit.messageHandlers.right.postMessage(message.data);
}


// NOTE(Issam): We need a way to clean these up. Maybe from swift when webview is destroyed 
// We send over a ForceShutdown message.
const channels = new Map();

window.receive = (message) => {
  const id = message?.channelId;
  // TODO(Issam): This is a bit hacky but works for now.
  switch (message?.type) {
    case "StartTranslation": {
      // Create a fresh MessageChannel for each new translation start
      // TODO(Issam): This might be wasteful maybe ??? Also when do we kill them ?
      const channel = new MessageChannel();
      channels.set(id, channel);
      const { port1, port2 } = channel;
      port2.onmessage = (msg) => sendToPage(msg);
      handleActorMessage({ ...message, port: port1 });
      break;
    }
    case "DiscardTranslations":
    case "ForceShutdown": {
      handleActorMessage(message);
      // We need to delete this after we send over the messages and the engine is really done.
      channels.delete(id);
      break;
    }
    default: {
      const channel = channels.get(id);
      channel?.port2.postMessage(message);
      break;
    }
  }
}