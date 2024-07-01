// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import WebKit

class MetadataParserHelper: TabEventHandler {
    let tabEventWindowResponseType: TabEventHandlerWindowResponseType = .allWindows

    init() {
        register(self, forTabEvents: .didChangeURL)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        // Get the metadata out of the page-metadata-parser, and into a type safe struct as soon
        // as possible.
        guard let webView = tab.webView,
            let url = webView.url, url.isWebPage(includeDataURIs: false), !InternalURL.isValid(url: url) else {
                tab.pageMetadata = nil
                return
        }
        webView.evaluateJavascriptInDefaultContentWorld(
            "__firefox__.metadata && __firefox__.metadata.getMetadata()"
        ) { result, error in
            guard error == nil else {
                tab.pageMetadata = nil
                return
            }

            guard let dict = result as? [String: Any],
                  let pageMetadata = PageMetadata.fromDictionary(dict) else {
                tab.pageMetadata = nil
                return
            }

            tab.pageMetadata = pageMetadata
            TabEvent.post(.didLoadPageMetadata(pageMetadata), for: tab)
        }
    }
}
