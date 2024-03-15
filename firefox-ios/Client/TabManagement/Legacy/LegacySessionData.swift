// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

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
        self.urls = []
        self.lastUsedTime = lastUsedTime
    }
}
