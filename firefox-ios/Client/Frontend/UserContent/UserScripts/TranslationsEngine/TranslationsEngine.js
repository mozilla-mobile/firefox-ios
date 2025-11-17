import "Assets/CC_Script/TranslationsHelpers.mjs";
import { handleActorMessage } from "Assets/CC_Script/translations-engine.sys.mjs";

/// NOTE: This sends messages from the engine to the content process.
const sendToPage = (message) => {
  window.webkit.messageHandlers.right.postMessage(message.data);
}


/// NOTE: This keeps track of the channels for each translation actor.
/// These are cleaned up when a translation is discarded or the engine is shutdown.
const channels = new Map();


/// NOTE: This receives messages from the content process. 
// Depending on the message type, we might need to do pre-processing, before sending to the engine.
window.receive = (message) => {
  const id = message?.channelId;
  switch (message?.type) {
    case "StartTranslation": {
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