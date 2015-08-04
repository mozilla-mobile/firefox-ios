/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

import Shared

class SessionData: NSObject, NSCoding {
    let currentPage: Int
    let urls: [NSURL]
    let lastUsedTime: Timestamp

    init(currentPage: Int, urls: [NSURL], lastUsedTime: Timestamp) {
        self.currentPage = currentPage
        self.urls = urls
        self.lastUsedTime = lastUsedTime
    }

    required init(coder: NSCoder) {
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