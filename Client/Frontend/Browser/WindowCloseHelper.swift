/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol WindowCloseHelperDelegate: class {
    func windowCloseHelper(_ windowCloseHelper: WindowCloseHelper, didRequestToCloseTab tab: Tab)
}

class WindowCloseHelper: TabHelper {
    weak var delegate: WindowCloseHelperDelegate?
    private weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
        if let path = Bundle.main.pathForResource("WindowCloseHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "windowCloseHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let tab = tab {
            DispatchQueue.main.async {
                self.delegate?.windowCloseHelper(self, didRequestToCloseTab: tab)
            }
        }
    }

    class func name() -> String {
        return "WindowCloseHelper"
    }
}
