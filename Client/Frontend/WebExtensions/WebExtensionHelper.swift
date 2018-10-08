/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import WebKit

class WebExtensionHelper: TabContentScript {
    fileprivate weak var tab: Tab?

    class func name() -> String {
        return "WebExtensionHelper"
    }

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "webExtensionAPI"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard message.name == "webExtensionAPI",
            let body = message.body as? [String : Any?],
            let extensionId = body["pipeId"] as? String,
            let webExtension = WebExtensionManager.default.webExtensions.find({ $0.id == extensionId }) else {
            return
        }

        webExtension.interface.userContentController(userContentController, didReceive: message)
    }
}
