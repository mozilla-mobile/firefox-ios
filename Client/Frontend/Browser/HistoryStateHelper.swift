/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol HistoryStateHelperDelegate: class {
    func historyStateHelper(_ historyStateHelper: HistoryStateHelper, didPushOrReplaceStateInTab tab: Tab)
}

// This tab helper is needed for injecting a user script into the
// WKWebView that intercepts calls to `history.pushState()` and
// `history.replaceState()` so that the BrowserViewController is
// notified when the user navigates a single-page web application.
class HistoryStateHelper: TabContentScript {
    weak var delegate: HistoryStateHelperDelegate?
    fileprivate weak var tab: Tab?
    
    required init(tab: Tab) {
        self.tab = tab
    }
    
    func scriptMessageHandlerName() -> String? {
        return "historyStateHelper"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let tab = tab {
            DispatchQueue.main.async {
                self.delegate?.historyStateHelper(self, didPushOrReplaceStateInTab: tab)
            }
        }
    }
    
    class func name() -> String {
        return "HistoryStateHelper"
    }
}
