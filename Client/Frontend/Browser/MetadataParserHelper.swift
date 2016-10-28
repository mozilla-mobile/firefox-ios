/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import WebKit
import WebMetadataKit

private let log = Logger.browserLogger

class MetadataParserHelper: TabHelper {
    private weak var tab: Tab?
    private let profile: Profile
    private var parser: WebMetadataParser?

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
        self.parser = WebMetadataParser()
        self.parser?.addUserScriptsIntoWebView(tab.webView!)
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
