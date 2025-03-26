// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

class FocusContentScript: WKContentScript {
    private let logger: Logger
    private weak var delegate: ContentScriptDelegate?

    init(delegate: ContentScriptDelegate?,
         logger: Logger = DefaultLogger.shared) {
        self.delegate = delegate
        self.logger = logger
    }

    static func name() -> String {
        return "FocusContent"
    }

    func scriptMessageHandlerNames() -> [String] {
        return ["focusHelper"]
    }

    func userContentController(didReceiveMessage message: Any) {
        guard let data = message as? [String: String] else {
            logger.log("FocusHelper.js sent the wrong message", level: .debug, category: .webview)
            return
        }

        guard let eventType = data["eventType"], data["elementType"] != nil else {
            logger.log("FocusHelper.js sent the wrong data", level: .debug, category: .webview)
            return
        }

        if eventType == "focus" {
            delegate?.contentScriptDidSendEvent(.fieldFocusChanged(true))
        } else if eventType == "blur" {
            delegate?.contentScriptDidSendEvent(.fieldFocusChanged(false))
        } else {
            logger.log("FocusHelper.js sent the wrong data", level: .debug, category: .webview)
        }
    }
}
