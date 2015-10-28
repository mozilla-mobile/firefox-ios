/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol SessionRestoreHelperDelegate: class {
    func sessionRestoreHelper(helper: SessionRestoreHelper, didRestoreSessionForBrowser browser: Browser)
}

class SessionRestoreHelper: BrowserHelper {
    weak var delegate: SessionRestoreHelperDelegate?
    private weak var browser: Browser?

    required init(browser: Browser) {
        self.browser = browser
    }

    func scriptMessageHandlerName() -> String? {
        return "sessionRestoreHelper"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let browser = browser, params = message.body as? [String: AnyObject] {
            if params["name"] as! String == "didRestoreSession" {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.sessionRestoreHelper(self, didRestoreSessionForBrowser: browser)
                }
            }
        }
    }

    class func name() -> String {
        return "SessionRestoreHelper"
    }
}
