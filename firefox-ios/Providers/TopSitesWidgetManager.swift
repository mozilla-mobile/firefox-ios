// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WidgetKit
import Shared
import Common
import Storage

protocol TopSitesWidget {
    /// Write top sites to widgetkit
    @available(iOS 14.0, *)
    func writeWidgetKitTopSites()
}

class TopSitesWidgetManager: TopSitesWidget {
    private let topSitesProvider: TopSitesProvider
    private let userDefaults: UserDefaultsInterface

    init(topSitesProvider: TopSitesProvider,
         userDefaults: UserDefaultsInterface = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier) ?? .standard) {
        self.topSitesProvider = topSitesProvider
        self.userDefaults = userDefaults
    }

    @available(iOS 14.0, *)
    func writeWidgetKitTopSites() {
        topSitesProvider.getTopSites { sites in
            guard let sites = sites else { return }

            // save top sites for widgetkit use
            self.save(topSites: sites)
            // Update widget timeline
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func save(topSites: [Site]) {
        userDefaults.removeObject(forKey: PrefsKeys.WidgetKitSimpleTopTab)

        guard let encodedData = try? Site.encode(with: JSONEncoder(), data: topSites) else { return }
        userDefaults.set(encodedData, forKey: PrefsKeys.WidgetKitSimpleTopTab)
    }
}
