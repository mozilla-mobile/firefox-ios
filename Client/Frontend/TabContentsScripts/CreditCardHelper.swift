// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import WebKit


class CreditCardHelper: TabContentScript {

    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "CreditCardHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "creditCardMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String : AnyObject] else {return}
        print("Received from content script: " , data);

        guard let webView = tab?.webView else {return}
        webView.evaluateJavascriptInDefaultContentWorld("window.__firefox__.CreditCardHelper.fillCreditCardInfo(\"pong\")")
    }

}
