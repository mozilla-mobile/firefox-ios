
/* This Source Code Form is subject to the terms of the Mozilla Public
 + * License, v. 2.0. If a copy of the MPL was not distributed with this
 + * file, You can obtain one at http:mozilla.org/MPL/2.0/. */

(function() {
  if (!window.__firefox__) {
    window.__firefox__ = {};
  }
  var observers = [];
  var isEnabled = false;

  function initializeStyleSheet () {
    var no_image_css_id = "iBrowser_no_image_css";
    var no_image_css = '*{background-image:none !important;}img,iframe{visibility:hidden !important;}';
    var newCss = document.getElementById(no_image_css_id);
    if(newCss == undefined){
        var cssStyle = document.createElement('style');
        cssStyle.type = 'text/css';
        cssStyle.id = no_image_css_id;
        if (cssStyle.styleSheet) {
            cssStyle.styleSheet.cssText = no_image_css;
        } else {
            cssStyle.appendChild(document.createTextNode(no_image_css));
        }
        document.documentElement.appendChild(cssStyle);
    } else {
        newCss.innerHTML = no_image_css;
    }
  }

  function blockImages (elem, enabled) {
    var imgs = document.getElementsByTagName("IMG");
    for (var i=0; i<imgs.length;i++) {
        var parent = imgs[i].parentNode;
        parent.removeChild(imgs[i]);
    }
  }

  function watchForImages (elem, enabled) {
    var observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            blockImages(mutation.addedNodes, enabled);
        });
    });
    // configuration of the observer:
    var config = { childList: true, subtree: true };
    // pass in the target node, as well as the observer options
    observer.observe(target, config);
    observers.push(observer);
  }

  window.__firefox__.setNoImageMode = function (enabled) {
    isEnabled = enabled;
    for (var i=0; i<observers.length; i++) {
        var observer = observers.shift();
        observer.disconnect();
    }
    if (enabled) {
        initializeStyleSheet();
        var bodys = document.getElementsByTagName("body");
        for (var i=0; i<bodys.length; i++) {
            blockImages(bodys[i], isEnabled);
            watchForImages(bodys[i], isEnabled);
        }
    }
  }

  window.addListener("DOMContentLoaded", function (event) {
    setNoImageMode(isEnabled);
  });
})();