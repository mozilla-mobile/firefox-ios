/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class CustomSearchHelper: TabHelper {
    fileprivate weak var tab: Tab?

    required init(tab: Tab) {
        self.tab = tab
        if let path = Bundle.main.path(forResource: "CustomSearchHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
                tab.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "customSearchHelper"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        //We don't listen to messages because the BVC calls the searchHelper script by itself.
    }

    class func name() -> String {
        return "CustomSearchHelper"
    }
}
