/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

protocol WindowEventsHelperDelegate: class {
    func windowEventsHelperDidClose(_: WindowEventsHelper)
}

/**
 * This class provides the functionality needed to fix buggy behavior in the forward and back buttons in the browser
 * when there is an anchor URL. This class executes a JS script that adds and event listener to the browser such that whenever
 * there is an anchor URL (and event known as a 'hashchange' in JS), it sends a message back to the class, firing off the
 * delegate which then updates the back and forward statuses of the toolbar. This fixes the buggy behavior in these situations
 *
 * (Helper script to keep the history state in sync with fragment identifiers. WKWebView doesn't fire didCommitNavigation for hashchange events, so we need to manage it ourselves)
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
        let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
        browser.webView!.configuration.userContentController.addUserScript(userScript)
    }

    func scriptMessageHandlerName() -> String? {
        return "windowEventsMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        delegate?.windowEventsHelperDidClose(self)
    }
}
