/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol WindowCloseHelperDelegate: class {
    func windowCloseHelper(windowCloseHelper: WindowCloseHelper, didRequestToCloseBrowser browser: Browser)
}

class WindowCloseHelper: BrowserHelper {
    weak var delegate: WindowCloseHelperDelegate?
    private weak var browser: Browser?

    required init(browser: Browser) {
        self.browser = browser
        if let path = NSBundle.mainBundle().pathForResource("WindowCloseHelper", ofType: "js") {
            if let source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
                let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView!.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "windowCloseHelper"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let browser = browser {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.windowCloseHelper(self, didRequestToCloseBrowser: browser)
            }
        }
    }

    class func name() -> String {
        return "WindowCloseHelper"
    }
}
