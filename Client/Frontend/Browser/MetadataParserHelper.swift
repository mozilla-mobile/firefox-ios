/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import WebKit

private let log = Logger.browserLogger

class MetadataParserHelper: TabContentScript {
    private weak var tab: Tab?
    private let profile: Profile

    class func name() -> String {
        return "MetadataParserHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile
    }

    func scriptMessageHandlerName() -> String? {
        return "metadataMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // Get the metadata out of the page-metadata-parser, and into a type safe struct as soon
        // as possible.
        guard let dict = message.body as? [String: Any],
            let tab = self.tab,
            let pageURL = tab.url?.displayURL,
            let pageMetadata = PageMetadata.fromDictionary(dict) else {
                log.debug("Page contains no metadata!")
                return
        }

        let userInfo: [String: Any] = [
            "isPrivate": self.tab?.isPrivate ?? true,
            "pageMetadata": pageMetadata,
            "tabURL": pageURL
        ]

        tab.pageMetadata = pageMetadata

        TabEvent.post(.didLoadPageMetadata(pageMetadata), for: tab)
        NotificationCenter.default.post(name: .OnPageMetadataFetched, object: nil, userInfo: userInfo)
    }
}
