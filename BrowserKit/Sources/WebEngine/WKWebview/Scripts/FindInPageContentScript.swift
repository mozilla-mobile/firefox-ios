// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

protocol FindInPageHelperDelegate: AnyObject {
    func findInPageHelper(_ findInPageContentScript: FindInPageContentScript, didUpdateCurrentResult currentResult: Int)
    func findInPageHelper(_ findInPageContentScript: FindInPageContentScript, didUpdateTotalResults totalResults: Int)
}

class FindInPageContentScript: WKContentScript {
    weak var delegate: FindInPageHelperDelegate?
    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    class func name() -> String {
        return "FindInPage"
    }

    func scriptMessageHandlerNames() -> [String] {
        return ["findInPageHandler"]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let parameters = message.body as? [String: String],
              let token = parameters["appIdToken"],
              token == DefaultUserScriptManager.appIdToken else {
            logger.log("FindInPage.js sent wrong type of message",
                       level: .warning,
                       category: .webview)
            return
        }

        if let currentResult = parameters["currentResult"], let result = Int(currentResult) {
            delegate?.findInPageHelper(self, didUpdateCurrentResult: result)
        }

        if let totalResults = parameters["totalResults"], let result = Int(totalResults) {
            delegate?.findInPageHelper(self, didUpdateTotalResults: result)
        }
    }
}
