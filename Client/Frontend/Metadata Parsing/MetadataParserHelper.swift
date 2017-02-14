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

        tab.injectUserScriptWith(fileName: "page-metadata-parser")
        tab.injectUserScriptWith(fileName: "MetadataHelper")
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any] else {
            return
        }
        
        var userInfo = [String: Any]()
        userInfo["isPrivate"] = self.tab?.isPrivate ?? true
        userInfo["metadata"] = dict
        NotificationCenter.default.post(name: NotificationOnPageMetadataFetched, object: nil, userInfo: userInfo)
    }
}
