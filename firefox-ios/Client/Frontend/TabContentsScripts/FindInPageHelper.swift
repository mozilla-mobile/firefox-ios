// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit

protocol FindInPageHelperDelegate: AnyObject {
    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateCurrentResult currentResult: Int)
    func findInPageHelper(_ findInPageHelper: FindInPageHelper, didUpdateTotalResults totalResults: Int)
}

class FindInPageHelper: TabContentScript {
    weak var delegate: FindInPageHelperDelegate?
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "FindInPage"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["findInPageHandler"]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let data = message.body as? [String: Int] else {
            fatalError("Invalid data message body: \(message.body)")
        }

        if let currentResult = data["currentResult"] {
            delegate?.findInPageHelper(self, didUpdateCurrentResult: currentResult)
        }

        if let totalResults = data["totalResults"] {
            delegate?.findInPageHelper(self, didUpdateTotalResults: totalResults)
        }
    }
}
