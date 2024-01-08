// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// PR: https://github.com/mozilla-mobile/firefox-ios/pull/4387
/// Commit: https://github.com/mozilla-mobile/firefox-ios/commit/8b1450fbeb87f1f559a2f8e42971c715dc96bcaf
/// InternalURL helps  encapsulate all internal scheme logic for urls rather than using URL extension.
/// Extensions to built-in classes should be more minimal that what was being done previously.
/// This migration was required mainly for above PR which is related to a PI request that
/// reduces security risk. Also, this particular method helps in cleaning up / migrating
/// old localhost:6571 URLs to internal: SessionData urls 
private func migrate(urls: [URL]) -> [URL] {
    return urls.compactMap { url in
        var url = url
        let port = AppInfo.webserverPort
        [(
            "http://localhost:\(port)/errors/error.html?url=",
            "\(InternalURL.baseUrl)/\(SessionRestoreHandler.path)?url="
        )
         // TODO: handle reader pages
         // ("http://localhost:6571/reader-mode/page?url=", "\(InternalScheme.url)/\(ReaderModeHandler.path)?url=")
        ].forEach { oldItem, newItem in
            if url.absoluteString.hasPrefix(oldItem) {
                var urlStr = url.absoluteString.replacingOccurrences(of: oldItem, with: newItem)
                let comp = urlStr.components(separatedBy: newItem)
                if comp.count > 2 {
                    // get the last instance of incorrectly nested urls
                    urlStr = newItem + (comp.last ?? "")
                    assertionFailure(
                        "SessionData urls have nested internal links, investigate: [\(url.absoluteString)]"
                    )
                }
                url = URL(string: urlStr, invalidCharacters: false) ?? url
            }
        }

        if let internalUrl = InternalURL(url), internalUrl.isAuthorized,
            let stripped = URL(string: internalUrl.stripAuthorization, invalidCharacters: false) {
            return stripped
        }

        return url
    }
}

class LegacySessionData: Codable {
    let currentPage: Int
    let lastUsedTime: Timestamp
    let urls: [URL]

    enum CodingKeys: String, CodingKey {
        case currentPage
        case lastUsedTime
        case urls
    }

    /**
        Creates a new SessionData object representing a serialized tab.

        - parameter currentPage:     The active page index. Must be in the range of (-N, 0],
                                where 1-N is the first page in history, and 0 is the last.
        - parameter urls:            The sequence of URLs in this tab's session history.
        - parameter lastUsedTime:    The last time this tab was modified.
    **/
    init(currentPage: Int, urls: [URL], lastUsedTime: Timestamp) {
        self.currentPage = currentPage
        self.urls = migrate(urls: urls)
        self.lastUsedTime = lastUsedTime
    }
}
