/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

(function() {
    var nativeHistoryPushState = window.history.pushState;
    var nativeHistoryReplaceState = window.history.replaceState;

    // We need to catch calls to `history.pushState()` in order to
    // notify the BrowserViewController so that history can be
    // recorded in single-page web applications that do all rendering
    // on the client side.
    window.history.pushState = function(state, title, url) {
        nativeHistoryPushState.apply(this, arguments);
        webkit.messageHandlers.historyStateHelper.postMessage({
            pushState: true,
            state: state,
            title: title,
            url: url
        });
    };

    // We need to catch calls to `history.replaceState()` in order to
    // notify the BrowserViewController so that history can be
    // recorded in single-page web applications that do all rendering
    // on the client side.
    window.history.replaceState = function(state, title, url) {
      nativeHistoryReplaceState.apply(this, arguments);
      webkit.messageHandlers.historyStateHelper.postMessage({
          replaceState: true,
          state: state,
          title: title,
          url: url
      });
    };
})();
