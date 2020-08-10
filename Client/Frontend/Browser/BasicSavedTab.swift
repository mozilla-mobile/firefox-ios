/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Storage
import Shared

// A simpler version of SavedTab, meant for use in extensions.
// Intentionally does not rely on other classes like Tab
class BasicSavedTab: NSObject, NSCoding {
    let title: String?
    let isPrivate: Bool
    let url: URL?
    var screenshotUUID: UUID?
    var faviconURL: String?
    
    var jsonDictionary: [String: AnyObject] {
        let title: String = self.title ?? "null"
        let faviconURL: String = self.faviconURL ?? "null"
        let uuid: String = self.screenshotUUID?.uuidString ?? "null"
        
        let json: [String: AnyObject] = [
            "title": title as AnyObject,
            "isPrivate": String(self.isPrivate) as AnyObject,
            "faviconURL": faviconURL as AnyObject,
            "screenshotUUID": uuid as AnyObject,
            "url": url as AnyObject
        ]

        return json
    }
    
    init?(tab: SimpleTab, isSelected: Bool) {
        assert(Thread.isMainThread)
        
        self.screenshotUUID = tab.screenshotUUID as UUID?
        self.title = tab.title
        self.isPrivate = tab.isPrivate
        self.faviconURL = tab.faviconURL
        self.url = tab.url
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.screenshotUUID = coder.decodeObject(forKey: "screenshotUUID") as? UUID
        self.title = coder.decodeObject(forKey: "title") as? String
        self.isPrivate = coder.decodeBool(forKey: "isPrivate")
        self.faviconURL = coder.decodeObject(forKey: "faviconURL") as? String
        self.url = coder.decodeObject(forKey: "url") as? URL
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(screenshotUUID, forKey: "screenshotUUID")
        coder.encode(title, forKey: "title")
        coder.encode(isPrivate, forKey: "isPrivate")
        coder.encode(faviconURL, forKey: "faviconURL")
        coder.encode(url, forKey: "url")
    }
}

struct SimpleTab {
    let title: String?
    let url: URL?
    let isPrivate: Bool
    var screenshotUUID: UUID?
    var faviconURL: String?
}
