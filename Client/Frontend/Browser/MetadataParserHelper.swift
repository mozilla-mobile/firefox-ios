/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import WebKit

private let log = Logger.browserLogger

class MetadataParserHelper: TabHelper {
    private weak var tab: Tab?
    private let profile: Profile

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile

        if let libraryPath = NSBundle.mainBundle().pathForResource("page-metadata-parser.bundle", ofType: "js"),
           let parserWrapperPath = NSBundle.mainBundle().pathForResource("MetadataParser", ofType: "js"),
           librarySource = try? NSString(contentsOfFile: libraryPath, encoding: NSUTF8StringEncoding) as String,
           parserWrapperSource = try? NSString(contentsOfFile: parserWrapperPath, encoding: NSUTF8StringEncoding) as String {

            // Load in the page-metadata-parser library first so our wrapper can reference it
            let libraryUserScript = WKUserScript(source: librarySource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(libraryUserScript)

            // Load in our WKUserScript wrapper on top of the library second
            let parserWrapperUserScript = WKUserScript(source: parserWrapperSource, injectionTime: .AtDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(parserWrapperUserScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let dict = message.body as? [String: AnyObject] else {
            return
        }
        
        var userInfo = [String: AnyObject]()
        userInfo["isPrivate"] = self.tab?.isPrivate ?? true
        userInfo["metadata"] = dict
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationOnPageMetadataFetched, object: nil, userInfo: userInfo)
    }
}
