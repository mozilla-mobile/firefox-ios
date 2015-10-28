/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import Shared

class SessionData: NSObject, NSCoding {
    let currentPage: Int
    let urls: [NSURL]
    let lastUsedTime: Timestamp

    /**
        Creates a new SessionData object representing a serialized tab.

        - parameter currentPage:     The active page index. Must be in the range of (-N, 0],
                                where 1-N is the first page in history, and 0 is the last.
        - parameter urls:            The sequence of URLs in this tab's session history.
        - parameter lastUsedTime:    The last time this tab was modified.
    **/
    init(currentPage: Int, urls: [NSURL], lastUsedTime: Timestamp) {
        self.currentPage = currentPage
        self.urls = urls
        self.lastUsedTime = lastUsedTime

        assert(urls.count > 0, "Session has at least one entry")
        assert(currentPage > -urls.count && currentPage <= 0, "Session index is valid")
    }

    required init?(coder: NSCoder) {
        self.currentPage = coder.decodeObjectForKey("currentPage") as? Int ?? 0
        self.urls = coder.decodeObjectForKey("urls") as? [NSURL] ?? []
        self.lastUsedTime = UInt64(coder.decodeInt64ForKey("lastUsedTime")) ?? NSDate.now()
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(currentPage, forKey: "currentPage")
        coder.encodeObject(urls, forKey: "urls")
        coder.encodeInt64(Int64(lastUsedTime), forKey: "lastUsedTime")
    }
}