// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

public enum FindInPageFunction: String {
    /// Find all the occurrences of this text in the page
    case find

    /// Find the next occurrence of this text in the page
    case findNext

    /// Find the previous occurrence of this text in the page
    case findPrevious
}

public protocol FindInPageHelperDelegate: AnyObject {
    func findInPageHelper(didUpdateCurrentResult currentResult: Int)
    func findInPageHelper(didUpdateTotalResults totalResults: Int)
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
        didReceiveMessage message: Any
    ) {
        guard let parameters = message as? [String: Int] else {
            // TODO: FXIOS-6463 - Integrate message handler check
            logger.log("FindInPage.js sent wrong type of message",
                       level: .warning,
                       category: .webview)
            return
        }

        if let currentResult = parameters["currentResult"] {
            delegate?.findInPageHelper(didUpdateCurrentResult: currentResult)
        }

        if let totalResults = parameters["totalResults"] {
            delegate?.findInPageHelper(didUpdateTotalResults: totalResults)
        }
    }
}
