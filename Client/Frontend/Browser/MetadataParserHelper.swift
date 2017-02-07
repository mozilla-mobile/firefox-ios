/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import WebKit
//import WebMetadataKit

private let log = Logger.browserLogger

class MetadataParserHelper: TabHelper {
    fileprivate weak var tab: Tab?
    fileprivate let profile: Profile
   // fileprivate var parser: WebMetadataParser?

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
        //self.parser = WebMetadataParser()
       // self.parser?.addUserScriptsIntoWebView(tab.webView!)
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard message.body is [String: AnyObject] else {
            return
        }
        
//        var userInfo = [String: AnyObject]()
//        userInfo["isPrivate"] = self.tab?.isPrivate as AnyObject?? ?? true as AnyObject?
//        userInfo["metadata"] = dict as AnyObject?
//        NotificationCenter.default.post(name: NotificationOnPageMetadataFetched, object: nil, userInfo: userInfo)
    }
}
