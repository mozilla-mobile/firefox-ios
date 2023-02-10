// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import WebKit
import Logger

class CreditCardHelper: TabContentScript {
    private weak var tab: Tab?
    private var logger: Logger = DefaultLogger.shared

    class func name() -> String {
        return "CreditCardHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "creditCardMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        guard let request = message.body as? [String: Any] else {return}

        // TODO: Retrieve response value from user selected credit card
        // Example value: [
        //     "data": [
        //         "cc-name": "Jane Doe",
        //         "cc-number": "5555555555554444",
        //         "cc-exp-month": "05",
        //         "cc-exp-year": "2028",
        //       ],
        //     "id": request["id"]!,
        // ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: "asd")
            guard let jsonDataVal = String(data: jsonData, encoding: .utf8) else { return }
            let fillCreditCardInfoCallback = "window.__firefox__.CreditCardHelper.fillCreditCardInfo('\(jsonDataVal)')"
            guard let webView = tab?.webView else {return}
            webView.evaluateJavascriptInDefaultContentWorld(fillCreditCardInfoCallback)
        } catch let error as NSError {
            logger.log("Credit card script error \(error)",
                       level: .debug,
                       category: .webview)
        }
    }
}
