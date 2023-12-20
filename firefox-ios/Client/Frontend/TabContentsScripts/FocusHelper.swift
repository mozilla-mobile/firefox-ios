// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import WebKit

class FocusHelper: TabContentScript {
    private var logger: Logger
    private weak var tab: Tab?

    init(tab: Tab,
         logger: Logger = DefaultLogger.shared) {
        self.tab = tab
        self.logger = logger
    }

    static func name() -> String {
        return "FocusHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "focusHelper"
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String: String] else {
            logger.log("FocusHelper.js sent wrong type of message",
                       level: .warning,
                       category: .webview)
            return
        }

        guard data["elementType"] != nil,
              let eventType = data["eventType"]
        else {
            logger.log("FocusHelper.js sent wrong keys for message",
                       level: .warning,
                       category: .webview)
            return
        }

        switch eventType {
        case "focus":
            tab?.isEditing = true
        case "blur":
            tab?.isEditing = false
        default:
            logger.log("FocusHelper.js sent unhandled eventType",
                       level: .warning,
                       category: .webview)
            return
        }
    }
}
