/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol ReadabilityTabHelperDelegate {
    func readabilityTabHelper(readabilityTabHelper: ReadabilityTabHelper, didFinishWithReadabilityResult result: ReadabilityResult)
}

class ReadabilityTabHelper: TabHelper {
    var delegate: ReadabilityTabHelperDelegate?

    class func name() -> String {
        return "ReadabilityTabHelper"
    }

    init?(tab: Tab) {
        if let readabilityPath = NSBundle.mainBundle().pathForResource("Readability", ofType: "js"),
           let readabilitySource = try? NSMutableString(contentsOfFile: readabilityPath, encoding: NSUTF8StringEncoding),
           let readabilityTabHelperPath = NSBundle.mainBundle().pathForResource(ReadabilityTabHelper.name(), ofType: "js"),
           let readabilityTabHelperSource = try? NSMutableString(contentsOfFile: readabilityTabHelperPath, encoding: NSUTF8StringEncoding) {
            readabilityTabHelperSource.replaceOccurrencesOfString("%READABILITYJS%", withString: readabilitySource as String, options: NSStringCompareOptions.LiteralSearch, range: NSMakeRange(0, readabilityTabHelperSource.length))
            let userScript = WKUserScript(source: readabilityTabHelperSource as String, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readabilityMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let readabilityResult = ReadabilityResult(object: message.body) {
            delegate?.readabilityTabHelper(self, didFinishWithReadabilityResult: readabilityResult)
        }
   }
}