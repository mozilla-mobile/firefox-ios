/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

if (webkit.messageHandlers.trackingProtectionStats) {
  install();
}

function install() {
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

  function sendMessage(url) {
    if (url) {
      webkit.messageHandlers.trackingProtectionStats.postMessage({ url: url });
    }
  }

  function onLoadNativeCallback() {
    // Send back the sources of every script and image in the DOM back to the host application.
    [].slice.apply(document.scripts).forEach(function(el) { sendMessage(el.src); });
    [].slice.apply(document.images).forEach(function(el) {
      // If the image's natural width is zero, then it has not loaded so we
      // can assume that it may have been blocked.
      if (el.src && el.complete && el.naturalWidth === 0) {
        sendMessage(el.src);
      }
    });
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
        Image.prototype.src = originalImageSrc;
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
      // Only attach the `error` event listener once for this
      // `XMLHttpRequest` instance.
      if (!_tpErrorHandler.get(this)) {
        // If this `XMLHttpRequest` instance fails to load, we
        // can assume it has been blocked.
        var tpErrorHandler = function() {
          sendMessage(_url.get(this));
        };
        _tpErrorHandler.set(this, tpErrorHandler);
        this.addEventListener("error", tpErrorHandler);
      }
      return originalXHRSend.apply(this, arguments);
    };

    // -------------------------------------------------
    // Send `fetch()` request URLs to the host application
    // -------------------------------------------------
    if (!originalFetch) {
      originalFetch = window.fetch;
    }

    window.fetch = function(input, init) {
      var result = originalFetch.apply(window, arguments);
      result.catch(function() {
        if (typeof input === 'string') {
          sendMessage(input);
        } else if (input instanceof Request) {
          sendMessage(input.url);
        }
      });
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
        // Only attach the `error` event listener once for this
        // Image instance.
        if (!_tpErrorHandler.get(this)) {
          // If this `Image` instance fails to load, we can assume
          // it has been blocked.
          let tpErrorHandler = () => {
            sendMessage(this.src);
          };

          _tpErrorHandler.set(this, tpErrorHandler);

          // Unfortunately, we need to wait a tick before attaching
          // our event listener otherwise we risk crashing the
          // WKWebView content process (Bug 1489543).
          requestAnimationFrame(() => {
            // Check if the error has already occurred before
            // we had a chance to attach our event listener.
            if (this.src && this.complete && this.naturalWidth === 0) {
              tpErrorHandler();
            }

            this.addEventListener("error", tpErrorHandler);
          });
        }

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
            // If the `<script>`  fails to load, we can assume
            // it has been blocked.
            node.addEventListener("error", function() {
              sendMessage(node.src);
            });
            return;
          }

          // `<iframe src="*">` elements where [src] is not "about:blank".
          if (node.tagName === "IFRAME" && node.src) {
            // Wait one tick before checking the `<iframe>`. If it is blocked
            // this is enough time before checking it.
            setTimeout(function() {
              if (node.src === "about:blank") {
                return;
              }

              try {
                // If an exception is thrown getting the <iframe>'s location,
                // then we can assume that the <iframe> loaded successfully
                // which means it was not blocked. If we can get the <iframe>'s
                // location and it is "about:blank", but the [src] attribute is
                // *not* "about:blank", then we can assume that the <iframe>
                // was blocked from loading.
                var frameHref = node.contentWindow.location.href;
                if (frameHref === "about:blank") {
                  sendMessage(node.src);
                }
              } catch (e) {}
            }, 1);
            return;
          }

          // `<link href="*">` elements.
          if (node.tagName === "LINK" && node.href) {
            // If the `<link>` fails to load, we can assume
            // it has been blocked.
            node.addEventListener("error", function() {
              sendMessage(node.href);
            });
            return;
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
}
