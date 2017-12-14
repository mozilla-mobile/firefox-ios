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
                set: function(target, property, value, receiver) {
                    // Setting certain properties on a `Window` returned from `window.open()`
                    // (which initially opens an "about:blank" tab) may not correctly take
                    // effect. To work around this, re-check after one tick of the run loop
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
                    if (['location', 'opener'].indexOf(property) > -1) {
                        setTimeout(function() {
                            if (target[property] !== value) {
                                target[property] = value;
                            }
                        }, 1);
                    }
                }
            });
        }

        // If no `Window` was returned from the native `window.open()`, the native
        // call was likely blocked for some reason. In that case, return `null`.
        return null;
    };
})();
