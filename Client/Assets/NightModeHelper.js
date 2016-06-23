/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
  if (!window.__firefox__) {
    window.__firefox__ = {};
  }
  var isEnabled = false;

  function initializeStyleSheet (enabled) {
    var night_css_id = "iBrowser_night_css";
    var night_css = ':not(body){color: #C8C8C8 !important; background-color:transparent !important;}body{-webkit-filter:brightness(.5) !important; background-color:#202020 !important;}';
    var newCss = document.getElementById(night_css_id);
    if (enabled) {
        if (!newCss) {
            var cssStyle = document.createElement('style');
            cssStyle.type = 'text/css';
            cssStyle.id = night_css_id;
                if (cssStyle.styleSheet) {
                    cssStyle.styleSheet.cssText = night_css;
                } else {
                    cssStyle.appendChild(document.createTextNode(night_css));
                }
            document.documentElement.appendChild(cssStyle);
        } else {
            newCss.innerHTML = night_css;
        }
    } else {
        if (newCss) {
            newCss.innerHTML = "";
        }
    }
  }

  window.__firefox__.setNightMode = function (enabled) {
    isEnabled = enabled;
    initializeStyleSheet(enabled);
  }

 window.addEventListener("DOMContentLoaded", function (event) {
    __firefox__.setNightMode(isEnabled);
  });
})();
