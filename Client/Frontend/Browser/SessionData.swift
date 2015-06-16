/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class SessionData: NSObject, NSCoding {
    let currentPage: Int
    let urls: [NSURL]

    init(currentPage: Int, urls: [NSURL]) {
        self.currentPage = currentPage
        self.urls = urls
    }

    required init(coder: NSCoder) {
        self.currentPage = coder.decodeObjectForKey("currentPage") as? Int ?? 0
        self.urls = coder.decodeObjectForKey("urls") as? [NSURL] ?? []
    }

    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(currentPage, forKey: "currentPage")
        coder.encodeObject(urls, forKey: "urls")
    }
}