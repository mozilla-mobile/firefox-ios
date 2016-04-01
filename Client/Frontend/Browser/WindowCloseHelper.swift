/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol WindowCloseHelperDelegate: class {
    func windowCloseHelper(windowCloseHelper: WindowCloseHelper, didRequestToCloseTab tab: Tab)
}

class WindowCloseHelper: TabHelper {
    weak var delegate: WindowCloseHelperDelegate?
    private weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
        if let path = NSBundle.mainBundle().pathForResource("WindowCloseHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "windowCloseHelper"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let tab = tab {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.windowCloseHelper(self, didRequestToCloseTab: tab)
            }
        }
    }

    class func name() -> String {
        return "WindowCloseHelper"
    }
}
