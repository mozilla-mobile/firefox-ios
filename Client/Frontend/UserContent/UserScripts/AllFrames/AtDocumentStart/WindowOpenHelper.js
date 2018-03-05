/* vim: set ts=2 sts=2 sw=2 et tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
"use strict";

var originalOpen = window.open;

window.open = function() {
  var openedWindow = originalOpen.apply(window, arguments);
  if (openedWindow) {
    // If we get a `Window` from the native `window.open()`, return a `Proxy` of it
    // so we can monitor property changes to address issues with "about:blank" tabs.
    return new Proxy(openedWindow, {
      set: function(target, key, value, receiver) {
        // Setting certain properties on a `Window` returned from `window.open()`
        // (which initially opens an "about:blank" tab) may not correctly take
        // effect. This may have something to do with the state of the `WKWebView`
        // in the view hierarchy. To work around this, re-check after a short delay
        // that the property was set correctly. This is sometimes used on the web
        // to open a link in a new tab without passing along any referrer info to
        // the target website by doing something like:
        //
        // ```
        // someLink.addEventListener('click', function(evt) {
        //     var newTab = window.open();
        //     newTab.opener = null;
        //     newTab.location = someLink.href;
        //     return false;
        // });
        // ```
        //
        // For more info, see Bug 1420267: https://bugzilla.mozilla.org/show_bug.cgi?id=1420267
        var originalSetter = Object.getOwnPropertyDescriptor(target, key).set;
        if (["location", "opener"].indexOf(key) > -1) {
          setTimeout(function() {
            if (target[key] !== value) {
              Reflect.apply(originalSetter, target, [value]);
            }
          }, 200);
          return true;
        }

        // Otherwise, if there's a setter defined for any other property, just
        // pass through the call as normal.
        if (originalSetter) {
          Reflect.apply(originalSetter, target, [value]);
          return true;
        }

        // Lastly, let any other properties without setters to be set as normal.
        return Reflect.set(target, key, value, receiver);
      }
    });
  }

  return openedWindow;
};

})();
