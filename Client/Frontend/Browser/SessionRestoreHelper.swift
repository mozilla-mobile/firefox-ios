/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol SessionRestoreHelperDelegate: class {
    func sessionRestoreHelper(helper: SessionRestoreHelper, didRestoreSessionForTab tab: Tab)
}

class SessionRestoreHelper: TabHelper {
    weak var delegate: SessionRestoreHelperDelegate?
    private weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
    }

    func scriptMessageHandlerName() -> String? {
        return "sessionRestoreHelper"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard AboutUtils.getAboutComponent(message.frameInfo.request.URL) == "sessionrestore" else { return }

        if let tab = tab, params = message.body as? [String: AnyObject] {
            if params["name"] as! String == "didRestoreSession" {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.sessionRestoreHelper(self, didRestoreSessionForTab: tab)
                }
            }
        }
    }

    class func name() -> String {
        return "SessionRestoreHelper"
    }
}
