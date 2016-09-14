/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 (function() {
  "use strict";

  if (!window.__firefox__) {
    window.__firefox__ = {};
  }

  window.__firefox__.NoImageMode = {
    enabled: false,
    setEnabled: null
  };

  var className = "__firefox__NoImageMode";
  var observer = null;

  function initializeStyleSheet () {
    var noImageCSS = "*{background-image:none !important;}img,iframe{visibility:hidden !important;}";
    var newCss = document.getElementById(className);
    if (!newCss) {
      var cssStyle = document.createElement("style");
      cssStyle.type = "text/css";
      cssStyle.id = className;
      cssStyle.appendChild(document.createTextNode(noImageCSS));
      document.documentElement.appendChild(cssStyle);
    } else {
      newCss.innerHTML = noImageCSS;
    }
  }

  window.__firefox__.NoImageMode.setEnabled = function (enabled) {
    if (enabled === window.__firefox__.NoImageMode.enabled) {
      return;
    }
    window.__firefox__.NoImageMode.enabled = enabled;
    if (enabled) {
      initializeStyleSheet();

      // Remove existing images on the page
      var images = document.body.getElementsByTagName("img");
      while (images.length > 0) {
        images[0].remove();
      }
      // Remove any images that are added to the page later
      observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
          for (var i = 0; i < mutation.addedNodes.length; ++ i) {
            if (mutation.addedNodes[i] instanceof HTMLImageElement) {
              mutation.addedNodes[i].remove();
            }
          }
        });
      });
      observer.observe(document.body, { childList: true, subtree: true });
    } else {
      // It would be useful to also revert the changes we've made, rather than just to prevent any more images from being loaded
      var style = document.getElementById(className);
      if (style) {
        style.remove();
      }
      observer.disconnect();
      observer = null;
    }
  }

  window.addEventListener("DOMContentLoaded", function (event) {
    window.__firefox__.NoImageMode.setEnabled(window.__firefox__.NoImageMode.enabled);
  });
})();