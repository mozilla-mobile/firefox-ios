// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared

open class ClosedTabsStore {

    private let prefs: Prefs
    private let maxNumberOfStoredClosedTabs = 10
    enum KeyedArchiverKeys: String {
        case recentlyClosedTabs
    }

    lazy open var tabs: [ClosedTab] = {
        guard let tabsArray: Data = self.prefs.objectForKey(KeyedArchiverKeys.recentlyClosedTabs.rawValue) as Any? as? Data,
              let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: tabsArray),
              let unarchivedArray = unarchiver.decodeObject(of: [NSArray.self, ClosedTab.self], forKey: KeyedArchiverKeys.recentlyClosedTabs.rawValue) as? [ClosedTab]
        else { return [] }
        return unarchivedArray
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    open func addTab(_ url: URL, title: String?, faviconURL: String?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title ?? "", faviconURL: faviconURL ?? "")
        tabs.insert(recentlyClosedTab, at: 0)
        if tabs.count > maxNumberOfStoredClosedTabs {
            tabs.removeLast()
        }
        let archivedTabsArray = try? NSKeyedArchiver.archivedData(withRootObject: tabs, requiringSecureCoding: true)
        prefs.setObject(archivedTabsArray, forKey: KeyedArchiverKeys.recentlyClosedTabs.rawValue)
    }

    open func popFirstTab() -> ClosedTab? {
        guard !tabs.isEmpty else { return nil }
        return tabs.removeFirst()
    }

    open func clearTabs() {
        prefs.removeObjectForKey(KeyedArchiverKeys.recentlyClosedTabs.rawValue)
        tabs = []
    }
}

open class ClosedTab: NSObject, NSCoding {

    enum CodingKeys: String {
        case url, title, faviconURL
    }

    public let url: URL
    public let title: String?
    public let faviconURL: String?

    var jsonDictionary: [String: Any] {
        let title = (self.title ?? "")
        let faviconURL = (self.faviconURL ?? "")
        let json: [String: Any] = [CodingKeys.title.rawValue: title,
                                   CodingKeys.url.rawValue: url,
                                   CodingKeys.faviconURL.rawValue: faviconURL]
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
        guard let url = coder.decodeObject(forKey: CodingKeys.url.rawValue) as? URL,
              let faviconURL = coder.decodeObject(forKey: CodingKeys.faviconURL.rawValue) as? String,
              let title = coder.decodeObject(forKey: CodingKeys.title.rawValue) as? String
        else { return nil }

        self.init(
            url: url,
            title: title,
            faviconURL: faviconURL
        )
    }

    open func encode(with coder: NSCoder) {
        coder.encode(url, forKey: CodingKeys.url.rawValue)
        coder.encode(faviconURL, forKey: CodingKeys.faviconURL.rawValue)
        coder.encode(title, forKey: CodingKeys.title.rawValue)
    }
}
