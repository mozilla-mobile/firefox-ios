/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class ClosedTabsStore {
    let prefs: Prefs

    lazy public var tabs: [ClosedTab] = {
        guard let tabsArray: Data = self.prefs.objectForKey("recentlyClosedTabs"),
              let unarchivedArray = NSKeyedUnarchiver.unarchiveObject(with: ta bsArray) as? [ClosedTab] else {
            return []
        }
        return unarchivedArray
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    public func addTab(_ url: URL, title: String?, faviconURL: String?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title ?? "", faviconURL: faviconURL ?? "")
        tabs.insert(recentlyClosedTab, at: 0)
        if tabs.count > 5 {
            tabs.removeLast()
        }
        let archivedTabsArray = NSKeyedArchiver.archivedData(withRootObject: tabs)
        prefs.setObject(archivedTabsArray, forKey: "recentlyClosedTabs")
    }

    public func clearTabs() {
        prefs.removeObjectForKey("recentlyClosedTabs")
        tabs = []
    }
}

public class ClosedTab: NSObject, NSCoding {
    public let url: URL
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

    init(url: URL, title: String?, faviconURL: String?) {
        assert(Thread.isMainThread)
        self.title = title
        self.url = url
        self.faviconURL = faviconURL
        super.init()
    }

    required convenience public init?(coder: NSCoder) {
        guard let url = coder.decodeObject(forKey: "url") as? URL,
              let faviconURL = coder.decodeObject(forKey: "faviconURL") as? String,
              let title = coder.decodeObject(forKey: "title") as? String else { return nil }

        self.init(
            url: url,
            title: title,
            faviconURL: faviconURL
        )
    }

    public func encode(with coder: NSCoder) {
        coder.encode(url, forKey: "url")
        coder.encode(faviconURL, forKey: "faviconURL")
        coder.encode(title, forKey: "title")
    }
}
