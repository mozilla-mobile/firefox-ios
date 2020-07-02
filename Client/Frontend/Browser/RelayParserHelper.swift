/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class RelayParserHelper: TabEventHandler {
    let prefs: Prefs

    init(prefs: Prefs) {
        self.prefs = prefs
        register(self, forTabEvents: .didChangeURL)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        guard let webView = tab.webView else { return }

        let apiKey = prefs.stringForKey("relay-api-key")
        let js = "let img = document.createElement('img');img.style.width='20px'; img.src='https://relay.firefox.com/static/images/placeholder-logo-beta.svg'; let emailInput = document.querySelector('input[type=email]');emailInput.parentNode.insertBefore(img, emailInput); img.onclick=function() {console.log(webkit.messageHandlers.relayMessageHandler); webkit.messageHandlers.relayMessageHandler.postMessage('buttonClicked');};"
        webView.evaluateJavaScript(js) { (result, error) in
            
        }
    }
}
