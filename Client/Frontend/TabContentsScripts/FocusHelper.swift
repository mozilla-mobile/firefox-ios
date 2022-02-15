// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import WebKit

private let log = Logger.browserLogger

class FocusHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    init(tab: Tab) {
        self.tab = tab
    }

    static func name() -> String {
        return "FocusHelper"
    }

    func scriptMessageHandlerName() -> String? {
        return "focusHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let data = message.body as? [String: String] else {
            return log.error("FocusHelper.js sent wrong type of message")
        }

        guard let _ = data["elementType"],
            let eventType = data["eventType"] else {
            return log.error("FocusHelper.js sent wrong keys for message")
        }

        switch eventType {
        case "focus":
            tab?.isEditing = true
        case "blur":
            tab?.isEditing = false
        default:
            return log.error("FocusHelper.js sent unhandled eventType")
        }
    }
}
