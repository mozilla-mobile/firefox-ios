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
    window.__firefox__.messages.close = "FIREFOX_MESSAGE_REDIRECT";
 
    var _close = window.close;
 
    window.close = function () {
        webkit.messageHandlers.windowCloseHelper.postMessage(null);
        _close.apply(this, arguments);
    };
    // A close message applies to the current window, so we need to execute the
    // close method in the context of the child window when we want to close a
    // window opened via window.open(). To do this we use window.postMessage, at
    // the expense of a side effect in the case of a website sending a message
    // identical to one contained in window.__firefox__.messages.close.
    window.addEventListener("message", function (event) {
        if (event.data === window.__firefox__.messages.close) {
            window.close();
            event.stopPropagation();
        }
    }, true);

    var _open = window.open;
    
    window.open = function (strUrl, strWindowName, strWindowFeatures) {
        // If we simply return the reference returned by window.open(),
        // then (the read-only) window.close() will fail to execute when the
        // opened window is cross-domain. Thus, we return a proxy object with an
        // overwritten .close() method to invoke our special handle function.
        opened = _open.apply(this, arguments);
        // If we can overwrite properties, then cross-origin restrictions don't apply,
        // so we can simply return the original window
        var urlHost;
        try {
            urlHost = new URL(strUrl).origin;
        } catch (error) {
            urlHost = null
        }
        var crossOrigin = window.location.origin !== urlHost;
        if (!crossOrigin) {
            return opened;
        }
        proxy = {};
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