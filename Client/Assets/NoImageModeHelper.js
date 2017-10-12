/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

if (!window.__firefox__) {
  Object.defineProperty(window, '__firefox__', {
    enumerable: false,
    configurable: false,
    writable: false,
    value: {}
  });
}

Object.defineProperty(window.__firefox__, 'NoImageMode', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: { enabled: false }
});

var className = "__firefox__NoImageMode";

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

Object.defineProperty(window.__firefox__.NoImageMode, 'setEnabled', {
  enumerable: false,
  configurable: false,
  writable: false,
  value: function(enabled) {
    if (enabled === window.__firefox__.NoImageMode.enabled) {
      return;
    }
    window.__firefox__.NoImageMode.enabled = enabled;
    if (enabled) {
      initializeStyleSheet();
      return;
    }

    // Disable no image mode //
    
    // It would be useful to also revert the changes we've made, rather than just to prevent any more images from being loaded
    var style = document.getElementById(className);
    if (style) {
      style.remove();
    }

    [].slice.apply(document.getElementsByTagName('img')).forEach(function(el) {
      var src = el.src;
      el.src = '';
      el.src = src;
    });

    [].slice.apply(document.querySelectorAll('[style*="background"]')).forEach(function(el) {
      var backgroundImage = el.style.backgroundImage;
      el.style.backgroundImage = 'none';
      el.style.backgroundImage = backgroundImage;
    });

    [].slice.apply(document.styleSheets).forEach(function(styleSheet) {
      [].slice.apply(styleSheet.rules || []).forEach(function(rules) {
        var style = rules.style;
        if (!style) {
          return;
        }

        var backgroundImage = style.backgroundImage;
        style.backgroundImage = 'none';
        style.backgroundImage = backgroundImage;
      });
    });
  }
});

window.addEventListener("DOMContentLoaded", function (event) {
  window.__firefox__.NoImageMode.setEnabled(window.__firefox__.NoImageMode.enabled);
});

})();

