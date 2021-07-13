/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class InactiveTabViewModel {
    var inactiveTabs = [Tab]()
    var normalTabs = [Tab]()
    var recentlyClosedTabs = [Tab]()
    private var tabs = [Tab]()
    private var selectedTab: Tab?

    func updateInactiveTabs(with selectedTab: Tab?, tabs: [Tab]) -> (inactiveTabs: [Tab], normalTabs: [Tab], recentlyClosedTabs: [Tab]) {
        self.tabs = tabs
        self.selectedTab = selectedTab
        let currentDate = Date()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
        let day4_Old = Calendar.current.date(byAdding: .day, value: -4, to: noon) ?? Date()
        let day30_Old = Calendar.current.date(byAdding: .day, value: -30, to: noon) ?? Date()
        clearAll()
        for tab in self.tabs {
            //Append selected tab to normal tab as we don't want to remove that
            let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)
            if tab == selectedTab || tabDate > day4_Old || tabTimeStamp == 0{
                normalTabs.append(tab)
            } else if tabDate <= day4_Old && tabDate >= day30_Old {
                inactiveTabs.append(tab)
            } else if tabDate < day30_Old {
                recentlyClosedTabs.append(tab)
            }
        }
        
        return (inactiveTabs, normalTabs, recentlyClosedTabs)
    }
    
    func clearAll() {
        inactiveTabs.removeAll()
        normalTabs.removeAll()
        recentlyClosedTabs.removeAll()
    }
}
