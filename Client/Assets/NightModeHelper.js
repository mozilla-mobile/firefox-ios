/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

 (function() {
  "use strict";

  if (!window.__firefox__) {
    window.__firefox__ = {};
  }

  window.__firefox__.NightMode = {
    enabled: false,
    setEnabled: null
  };

  var className = "__firefox__NightMode";

  function initializeStyleSheet () {
    var nightCSS = ":not(body){color: #C8C8C8 !important; background-color:transparent !important;}body{-webkit-filter:brightness(.5) !important; background-color:#202020 !important;}";
    var newCss = document.getElementById(className);
    if (!newCss) {
      var cssStyle = document.createElement("style");
      cssStyle.type = "text/css";
      cssStyle.id = className;
      cssStyle.appendChild(document.createTextNode(nightCSS));
      document.documentElement.appendChild(cssStyle);
    } else {
      newCss.innerHTML = nightCSS;
    }
  }

  window.__firefox__.NightMode.setEnabled = function (enabled) {
    if (enabled === window.__firefox__.NightMode.enabled) {
      return;
    }
    window.__firefox__.NightMode.enabled = enabled;
    if (enabled) {
      initializeStyleSheet();
    } else {
      var style = document.getElementById(className);
      if (style) {
        style.remove();
      }
    }
  }

  window.addEventListener("DOMContentLoaded", function (event) {
    window.__firefox__.NightMode.setEnabled(window.__firefox__.NightMode.enabled);
  });
 })();
