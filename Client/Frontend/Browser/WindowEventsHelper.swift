/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol WindowEventsHelperDelegate: class {
    func windowEventsHelperDidClose(_: WindowEventsHelper)
}

/**
 *
 */
class WindowEventsHelper: NSObject, BrowserHelper {
    weak var delegate: WindowEventsHelperDelegate?

    class func name() -> String {
        return "WindowEventsHelper"
    }

    required init(browser: Browser) {
        super.init()
        let path = NSBundle.mainBundle().pathForResource("WindowEventsHelper", ofType: "js")!
        let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as! String
        let userScript = WKUserScript(source: source, injectionTime: .AtDocumentStart, forMainFrameOnly: true)
        browser.webView!.configuration.userContentController.addUserScript(userScript)
    }

    func scriptMessageHandlerName() -> String? {
        return "windowEventsMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        println("Detected window event \(message.body). Calling delegate")

        if let eventType = message.body as? String {
            if eventType == "close" {
        delegate?.windowEventsHelperDidClose(self)
            } else if eventType == "test" {
                println("userScript is working and unpacking message.body")
            }
        }
    }
}
