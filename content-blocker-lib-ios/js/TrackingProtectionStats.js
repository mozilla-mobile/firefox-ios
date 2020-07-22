/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

if (webkit.messageHandlers.trackingProtectionStats) {
  install();
}

function install() {
  let _enabled = true

  Object.defineProperty(window.__firefox__, "TrackingProtectionStats", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {}
  });
  
  Object.defineProperty(window.__firefox__.TrackingProtectionStats, "setEnabled", {
    enumerable: false,
    configurable: false,
    writable: false,
    value: function(enabled, appIdToken) {
      if (appIdToken !== APP_ID_TOKEN || enabled === _enabled) {
        return;
      }

      _enabled = enabled;
      injectStatsTracking(enabled);
    }
  })

  let sendUrls = new Array();
  let sendUrlsTimeout = null;

  function sendMessage(url) {
    if (!_enabled) { return }
    
    try { 
      let mainDocHost = document.location.host;
      let u = new URL(url);
      // First party urls are not blocked
      if (mainDocHost === u.host) {
        return
      }
    } catch (e) {}

    if (url) {
      sendUrls.push(url)
    }
    
    // If already set, return
    if (sendUrlsTimeout) return;

    // Send the URLs in batches every 200ms to avoid perf issues 
    // from calling js-to-native too frequently. 
    sendUrlsTimeout = setTimeout(() => {
      sendUrlsTimeout = null;
      if (sendUrls.length < 1) return;
      webkit.messageHandlers.trackingProtectionStats.postMessage({ urls: sendUrls });
      sendUrls = new Array();
    }, 200);
  }

  function onLoadNativeCallback() {
    // Send back the sources of every script and image in the DOM back to the host application.
    [].slice.apply(document.scripts).forEach(function(el) { sendMessage(el.src); });
    [].slice.apply(document.images).forEach(function(el) { sendMessage(el.src); });
    [].slice.apply(document.getElementsByTagName('iframe')).forEach(function(el) { sendMessage(el.src); })
  }

  let originalXHROpen = null;
  let originalXHRSend = null;
  let originalFetch = null;
  let originalImageSrc = null;
  let mutationObserver = null;

  function injectStatsTracking(enabled) {
    // This enable/disable section is a change from the original Focus iOS version.
    if (enabled) {
      if (originalXHROpen) {
        return;
      }
      window.addEventListener("load", onLoadNativeCallback, false);
    } else {
      window.removeEventListener("load", onLoadNativeCallback, false);

      if (originalXHROpen) { // if one is set, then all the enable code has run
        XMLHttpRequest.prototype.open = originalXHROpen;
        XMLHttpRequest.prototype.send = originalXHRSend;
        window.fetch = originalFetch;
        // Image.prototype.src = originalImageSrc; // doesn't work to reset
        mutationObserver.disconnect();

        originalXHROpen = originalXHRSend = originalImageSrc = mutationObserver = null;
      }
      return;
    }

    // -------------------------------------------------
    // Send XHR request URLs to the host application
    // -------------------------------------------------
    if (!originalXHROpen) {
      originalXHROpen = XMLHttpRequest.prototype.open;
      originalXHRSend = XMLHttpRequest.prototype.send;
    }

    // WeakMaps for storing "private" properties that
    // are inaccessible to web content.
    var _url = new WeakMap();
    var _tpErrorHandler = new WeakMap();

    XMLHttpRequest.prototype.open = function(method, url) {
      _url.set(this, url);
      return originalXHROpen.apply(this, arguments);
    };

    XMLHttpRequest.prototype.send = function(body) {
      sendMessage(_url.get(this));
      return originalXHRSend.apply(this, arguments);
    };

    // -------------------------------------------------
    // Send `fetch()` request URLs to the host application
    // -------------------------------------------------
    if (!originalFetch) {
      originalFetch = window.fetch;
    }

    window.fetch = function(input, init) {
      if (typeof input === 'string') {
        sendMessage(input);
      } else if (input instanceof Request) {
        sendMessage(input.url);
      }

      var result = originalFetch.apply(window, arguments);
      return result;
    };

    // -------------------------------------------------
    // Detect when new sources get set on Image and send them to the host application
    // -------------------------------------------------
    if (!originalImageSrc) {
      originalImageSrc = Object.getOwnPropertyDescriptor(Image.prototype, "src");
    }
    delete Image.prototype.src;
    Object.defineProperty(Image.prototype, "src", {
      get: function() {
        return originalImageSrc.get.call(this);
      },
      set: function(value) {
        sendMessage(this.src);
        originalImageSrc.set.call(this, value);
      }
    });

    // -------------------------------------------------
    // Listen to when new <script> elements get added to the DOM
    // and send the source to the host application
    // -------------------------------------------------
    mutationObserver = new MutationObserver(function(mutations) {
      mutations.forEach(function(mutation) {
        mutation.addedNodes.forEach(function(node) {
          // `<script src="*">` elements.
          if (node.tagName === "SCRIPT" && node.src) {
            sendMessage(node.src);
            return;
          }
          if (node.tagName === "IMG" && node.src) {
            sendMessage(node.src);
            return;
          }

          // `<iframe src="*">` elements where [src] is not "about:blank".
          if (node.tagName === "IFRAME" && node.src) {
            if (node.src === "about:blank") {
              return;
            }

            sendMessage(node.src);
            return;
          }

          // `<link href="*">` elements.
          if (node.tagName === "LINK" && node.href) {
            sendMessage(node.href);
          }
        });
      });
    });

    mutationObserver.observe(document.documentElement, {
      childList: true,
      subtree: true
    });
  }

  injectStatsTracking(true);
}
