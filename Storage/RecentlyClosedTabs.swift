/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class ClosedTabsStore {
    let prefs: Prefs

    lazy public var tabs: [ClosedTab] = {
        guard let tabsArray: NSData = self.prefs.objectForKey("recentlyClosedTabs"),
              let unarchivedArray = NSKeyedUnarchiver.unarchiveObjectWithData(tabsArray) as? [ClosedTab] else {
            return []
        }
        return unarchivedArray
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public func addTab(url: NSURL, title: String?, faviconURL: String?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title ?? "", faviconURL: faviconURL ?? "")
        tabs.insert(recentlyClosedTab, atIndex: 0)
        if tabs.count > 5 {
            tabs.removeLast()
        }
        let archivedTabsArray = NSKeyedArchiver.archivedDataWithRootObject(tabs)
        prefs.setObject(archivedTabsArray, forKey: "recentlyClosedTabs")
    }

    public func clearTabs() {
        prefs.removeObjectForKey("recentlyClosedTabs")
        tabs = []
    }
}

public class ClosedTab: NSObject, NSCoding {
    public let url: NSURL
    public let title: String?
    public let faviconURL: String?

    var jsonDictionary: [String: AnyObject] {
        let json: [String: AnyObject] = [
            "title": title ?? "",
            "url": url,
            "faviconURL": faviconURL ?? "",
        ]
        return json
    }

    init(url: NSURL, title: String?, faviconURL: String?) {
        assert(NSThread.isMainThread())
        self.title = title
        self.url = url
        self.faviconURL = faviconURL
        super.init()
    }

    required convenience public init?(coder: NSCoder) {
        guard let url = coder.decodeObjectForKey("url") as? NSURL,
              let faviconURL = coder.decodeObjectForKey("faviconURL") as? String,
              let title = coder.decodeObjectForKey("title") as? String else { return nil }

        self.init(
            url: url,
            title: title,
            faviconURL: faviconURL
        )
    }

    public func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(url, forKey: "url")
        coder.encodeObject(faviconURL, forKey: "faviconURL")
        coder.encodeObject(title, forKey: "title")
    }
}
