// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Sentry
import Shared

// Struct that retrives saved tabs and simple tabs dictionary for WidgetKit
struct SiteArchiver {
    static func tabsToRestore(tabsStateArchivePath: String?) -> ([SavedTab], [String: SimpleTab]) {
        // Get simple tabs for widgetkit
        let simpleTabsDict = SimpleTab.getSimpleTabs()

        guard let tabStateArchivePath = tabsStateArchivePath,
              FileManager.default.fileExists(atPath: tabStateArchivePath),
              let tabData = try? Data(contentsOf: URL(fileURLWithPath: tabStateArchivePath)) else {
            return ([SavedTab](), simpleTabsDict)
        }

        let unarchiver = try NSKeyedUnarchiver(forReadingWith: tabData)
        unarchiver.setClass(SavedTab.self, forClassName: "Client.SavedTab")
        unarchiver.setClass(SessionData.self, forClassName: "Client.SessionData")
        unarchiver.decodingFailurePolicy = .setErrorAndReturn
        guard let tabs = unarchiver.decodeObject(forKey: "tabs") as? [SavedTab] else {
            SentryIntegration.shared.send( message: "Failed to restore tabs", tag: .tabManager, severity: .error, description: "\(unarchiver.error ??? "nil")")
            SimpleTab.saveSimpleTab(tabs: nil)
            return ([SavedTab](), simpleTabsDict)
        }

        return (tabs, simpleTabsDict)
    }
}
