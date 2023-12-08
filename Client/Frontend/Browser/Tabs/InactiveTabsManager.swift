// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol InactiveTabsManagerProtocol {
    func getInactiveTabs(tabs: [Tab]) -> [Tab]
}

class InactiveTabsManager: InactiveTabsManagerProtocol {
    func getInactiveTabs(tabs: [Tab]) -> [Tab] {
        var inactiveTabs = [Tab]()
        let currentDate = Date()
        let defaultOldDay: Date

        // Debug for inactive tabs to easily test in code
        if UserDefaults.standard.bool(forKey: PrefsKeys.FasterInactiveTabsOverride) {
            defaultOldDay = Calendar.current.date(byAdding: .second, value: -10, to: currentDate) ?? Date()
        } else {
            let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
            let day14Old = Calendar.current.date(byAdding: .day, value: -14, to: noon) ?? Date()
            defaultOldDay = day14Old
        }

        let regularTabs = tabs.filter({ $0.isPrivate == false })
        for tab in regularTabs {
            let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)

            if tabDate <= defaultOldDay {
                inactiveTabs.append(tab)
            }
        }
        return inactiveTabs
    }
}
