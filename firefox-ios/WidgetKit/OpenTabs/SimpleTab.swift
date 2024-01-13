// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import TabDataStore

private let userDefaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!

struct SimpleTab: Hashable, Codable {
    var title: String?
    var url: URL?
    let lastUsedTime: Timestamp? // From Session Data
    var faviconURL: String?
    var isPrivate = false
    var uuid: String = ""
    var imageKey: String {
        return url?.baseDomain ?? ""
    }
}

extension SimpleTab {
    static func getSimpleTabs() -> [String: SimpleTab] {
        if let tbs = userDefaults.object(forKey: PrefsKeys.WidgetKitSimpleTabKey) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let tabs = try jsonDecoder.decode([String: SimpleTab].self, from: tbs)
                return tabs
            } catch {}
        }
        return [String: SimpleTab]()
    }

    static func saveSimpleTab(tabs: [String: SimpleTab]?) {
        guard let tabs = tabs, !tabs.isEmpty else {
            userDefaults.removeObject(forKey: PrefsKeys.WidgetKitSimpleTabKey)
            return
        }
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabs) {
            userDefaults.set(encoded, forKey: PrefsKeys.WidgetKitSimpleTabKey)
        }
    }

    static func convertToSimpleTabs(_ tabs: [TabData]) -> [String: SimpleTab] {
        var simpleTabs: [String: SimpleTab] = [:]
        for tab in tabs {
            // Set URL
            let url = URL(string: tab.siteUrl)

            // Ignore `internal about` urls which corresponds to Home
            if url != nil, url!.absoluteString.starts(with: "internal://local/about/") {
                continue
            }

            // Set Title
            var title = tab.title ?? ""
            // There is no title then use the base url Ex https://www.mozilla.org/ will be short displayed as `mozilla`
            if title.isEmpty {
                title = url?.shortDisplayString ?? ""
            }

            // Key for simple tabs dictionary is tab UUID which is used to select proper tab when we send
            // UUID to NavigationRouter class handle widget url
            let uuidVal = tab.id.uuidString
            let value = SimpleTab(title: title,
                                  url: url,
                                  lastUsedTime: tab.lastUsedTime.toTimestamp(),
                                  faviconURL: tab.faviconURL,
                                  isPrivate: tab.isPrivate,
                                  uuid: uuidVal)
            simpleTabs[uuidVal] = value
        }
        return simpleTabs
    }
}
