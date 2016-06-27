/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function () {
    if (!window.__firefox__) {
        window.__firefox__ = {};
    }
    if (!window.__firefox__.messages) {
        window.__firefox__.messages = {};
    }
    window.__firefox__.messages.close = "FIREFOX_MESSAGE_CLOSE";
 
    var _close = window.close;
    window.close = function () {
        webkit.messageHandlers.windowCloseHelper.postMessage(null);
        _close();
    };
    // A close message applies to the current window, so we need to execute the
    // close method in the context of the child window when we want to close a
    // window opened via window.open(). To do this we use window.postMessage, at
    // the expense of a side effect in the case of a website sending a message
    // identical to one contained in window.__firefox__.messages.close.
    window.addEventListener("message", function (event) {
        if (event.data === window.__firefox__.messages.close) {
            window.close();
            event.stopPropogation();
        }
    }, true);
    var _open = window.open;
    window.open = function (strUrl, strWindowName, strWindowFeatures) {
        // If we simply return the reference returned by window.open(),
        // then (the read-only) window.close() will fail to execute when the
        // opened window is cross-domain. Thus, we return a proxy object with an
        // overwritten .close() method to invoke our special handle function.
        var opened = _open.apply(this, arguments);
        var proxy = {};
        for (var property in opened) {
            if (typeof opened[property] === "function") {
                proxy[property] = opened[property].bind(opened);
            } else {
                Object.defineProperty(proxy, property, {
                    get: function () {
                        return opened[property];
                    },
                    set: function (value) {
                        opened[property] = value;
                    }
                });
            }
        }
        proxy.close = function () {
            opened.postMessage(window.__firefox__.messages.close, "*");
        }
        return proxy;
    };
})();