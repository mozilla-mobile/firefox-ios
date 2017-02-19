/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

protocol ReadabilityTabHelperDelegate {
    func readabilityTabHelper(_ readabilityTabHelper: ReadabilityTabHelper, didFinishWithReadabilityResult result: ReadabilityResult)
}

class ReadabilityTabHelper: TabHelper {
    var delegate: ReadabilityTabHelperDelegate?

    class func name() -> String {
        return "ReadabilityTabHelper"
    }

    init?(tab: Tab) {
        if let readabilityPath = Bundle.main.path(forResource: "Readability", ofType: "js"),
           let readabilitySource = try? NSMutableString(contentsOfFile: readabilityPath, encoding: String.Encoding.utf8.rawValue),
           let readabilityTabHelperPath = Bundle.main.path(forResource: ReadabilityTabHelper.name(), ofType: "js"),
           let readabilityTabHelperSource = try? NSMutableString(contentsOfFile: readabilityTabHelperPath, encoding: String.Encoding.utf8.rawValue) {
            readabilityTabHelperSource.replaceOccurrences(of: "%READABILITYJS%", with: readabilitySource as String, options: NSString.CompareOptions.literal, range: NSRange(location: 0, length: readabilityTabHelperSource.length))
            let userScript = WKUserScript(source: readabilityTabHelperSource as String, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: true)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "readabilityMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if let readabilityResult = ReadabilityResult(object: message.body as AnyObject?) {
            delegate?.readabilityTabHelper(self, didFinishWithReadabilityResult: readabilityResult)
        }
   }
}
