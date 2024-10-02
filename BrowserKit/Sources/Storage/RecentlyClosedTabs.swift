// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

open class ClosedTabsStore {
    private let prefs: Prefs
    private let maxNumberOfStoredClosedTabs = 10
    enum KeyedArchiverKeys: String {
        case recentlyClosedTabs
    }

    open lazy var tabs: [ClosedTab] = {
        guard let tabsData: Data = self.prefs.objectForKey(
            KeyedArchiverKeys.recentlyClosedTabs.rawValue
        ) as Any? as? Data,
              let unarchivedTabs = try? NSKeyedUnarchiver
            .unarchivedObject(ofClasses: [NSArray.self, ClosedTab.self], from: tabsData) as? [ClosedTab]
        else { return [] }

        return unarchivedTabs
    }()

    public init(prefs: Prefs) {
        self.prefs = prefs
    }

    open func addTab(_ url: URL, title: String?, lastExecutedTime: Timestamp?) {
        let recentlyClosedTab = ClosedTab(url: url, title: title, lastExecutedTime: lastExecutedTime)
        tabs.insert(recentlyClosedTab, at: 0)
        if tabs.count > maxNumberOfStoredClosedTabs {
            tabs.removeLast()
        }

        saveTabs(tabs)
    }

    open func popFirstTab() -> ClosedTab? {
        guard !tabs.isEmpty else { return nil }
        return tabs.removeFirst()
    }

    open func clearTabs() {
        prefs.removeObjectForKey(KeyedArchiverKeys.recentlyClosedTabs.rawValue)
        tabs = []
    }

    open func removeTabsFromDate(_ date: Date) {
        let timestampToRemoveFrom = date.toTimestamp()
        // If lastExecutedTime wasn't present on tab, we do not delete that tab since information isn't available
        tabs = tabs.filter { $0.lastExecutedTime ?? 0 < timestampToRemoveFrom }

        saveTabs(tabs)
    }

    private func saveTabs(_ tabs: [ClosedTab]) {
        let archivedTabsArray = try? NSKeyedArchiver.archivedData(withRootObject: tabs, requiringSecureCoding: true)
        prefs.setObject(archivedTabsArray, forKey: KeyedArchiverKeys.recentlyClosedTabs.rawValue)
    }
}

open class ClosedTab: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { return true }
    enum CodingKeys: String {
        case url, title, lastExecutedTime
    }

    public let url: URL
    public let title: String?
    public let lastExecutedTime: Timestamp?

    init(url: URL, title: String?, lastExecutedTime: Timestamp?) {
        self.title = title
        self.url = url
        self.lastExecutedTime = lastExecutedTime
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let url = coder.decodeObject(of: [NSURL.self], forKey: CodingKeys.url.rawValue) as? URL,
              let title = coder.decodeObject(of: [NSString.self], forKey: CodingKeys.title.rawValue) as? String,
              let date = coder.decodeObject(forKey: CodingKeys.lastExecutedTime.rawValue) as? Timestamp
        else { return nil }

        self.title = title
        self.url = url
        self.lastExecutedTime = date
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(url, forKey: CodingKeys.url.rawValue)
        coder.encode(title, forKey: CodingKeys.title.rawValue)
        coder.encode(lastExecutedTime, forKey: CodingKeys.lastExecutedTime.rawValue)
    }
}
