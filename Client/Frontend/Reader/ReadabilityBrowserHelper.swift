/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol ReadabilityBrowserHelperDelegate {
    func readabilityBrowserHelper(readabilityBrowserHelper: ReadabilityBrowserHelper, didFinishWithReadabilityResult result: ReadabilityResult)
}

class ReadabilityBrowserHelper: BrowserHelper {
    var delegate: ReadabilityBrowserHelperDelegate?

    class func name() -> String {
        return "ReadabilityBrowserHelper"
    }

    init?(browser: Browser) {
        if let readabilityPath = NSBundle.mainBundle().pathForResource("Readability", ofType: "js"),
           let readabilitySource = try? NSMutableString(contentsOfFile: readabilityPath, encoding: NSUTF8StringEncoding),
           let readabilityBrowserHelperPath = NSBundle.mainBundle().pathForResource("ReadabilityBrowserHelper", ofType: "js"),
           let readabilityBrowserHelperSource = try? NSMutableString(contentsOfFile: readabilityBrowserHelperPath, encoding: NSUTF8StringEncoding) {
            readabilityBrowserHelperSource.replaceOccurrencesOfString("%READABILITYJS%", withString: readabilitySource as String, options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readabilityBrowserHelperSource.length))
            let userScript = WKUserScript(source: readabilityBrowserHelperSource as String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
            browser.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readabilityMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let readabilityResult = ReadabilityResult(object: message.body) {
            delegate?.readabilityBrowserHelper(self, didFinishWithReadabilityResult: readabilityResult)
        }
   }
}