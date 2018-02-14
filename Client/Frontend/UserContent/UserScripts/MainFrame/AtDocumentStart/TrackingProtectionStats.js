/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
  "use strict";

  Object.defineProperty(window.__firefox__, "TrackingProtectionStats", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: { enabled: false }
  });

  Object.defineProperty(window.__firefox__.TrackingProtectionStats, "setEnabled", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: function(enabled, securityToken) {
      if (securityToken !== SECURITY_TOKEN) {
        return;
      }
    
      if (enabled === window.__firefox__.TrackingProtectionStats.enabled) {
        return;
      }

      window.__firefox__.TrackingProtectionStats.enabled = enabled;

      injectStatsTracking(enabled);
    }
  })

  function onLoadNativeCallback() {
    var messageHandler = window.webkit.messageHandlers.focusTrackingProtection;
    var sendMessage = function(url) { messageHandler.postMessage({ url: url }) };

    // Send back the sources of every script and image in the dom back to the host applicaiton
    Array.prototype.map.call(document.scripts, function(t) { return t.src }).forEach(sendMessage);
    Array.prototype.map.call(document.images, function(t) { return t.src }).forEach(sendMessage);
  }

  let originalOpen = null;
  let originalSend = null;
  let originalImageSrc = null;  
  let mutationObserver = null;

  function injectStatsTracking(enabled) {
    if (enabled) {
      if (originalOpen != null) {
        return;
      }
      window.addEventListener("load", onLoadNativeCallback, false);
    } else {
      window.removeEventListener("load", onLoadNativeCallback, false);

      if (originalOpen != null) { // if one is set, then all the enable code has run
        XMLHttpRequest.prototype.open = originalOpen;
        XMLHttpRequest.prototype.send = originalSend;
        Image.prototype.src = originalImageSrc;
        mutationObserver.disconnect();

        originalOpen = originalSend = originalImageSrc = mutationObserver = null;
      }
      return;
    }

    var messageHandler = window.webkit.messageHandlers.focusTrackingProtection

    // -------------------------------------------------
    // Send ajax requests URLs to the host application
    // -------------------------------------------------
    var xhrProto = XMLHttpRequest.prototype;
    if (originalOpen == null) {
      originalOpen = xhrProto.open;
      originalSend = xhrProto.send;
    }

    xhrProto.open = function(method, url) {
      this._url = url;
      return originalOpen.apply(this, arguments);
    };

    xhrProto.send = function(body) {
      messageHandler.postMessage({
        url: this._url
      })
      return originalSend.apply(this, arguments)
    };

    // -------------------------------------------------
    // Detect when new sources get set on Image and send them to the host application
    // -------------------------------------------------
    if (originalImageSrc == null) {
      originalImageSrc = Object.getOwnPropertyDescriptor(Image.prototype, 'src');
    }
    delete Image.prototype.src;
    Object.defineProperty(Image.prototype, 'src', {
      get: function() {
        return originalImageSrc.get.call(this);
      },
      set: function(value) {
        messageHandler.postMessage({
          url: value
        })
        originalImageSrc.set.call(this, value);
      }
    });

    // -------------------------------------------------
    // Listen to when new <script> elements get added to the dom
    // and send the source to the host application
    // -------------------------------------------------
    mutationObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          if (node.tagName === 'SCRIPT') {
            messageHandler.postMessage({
              url: node.src
            })
          }
        });
      });
    });

    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true
    });
  }

  // Default to on because there is a delay in being able to enable/disable
  // from native, and we don't want to miss events
  window.__firefox__.TrackingProtectionStats.enabled = true;
  injectStatsTracking(true);
})();
