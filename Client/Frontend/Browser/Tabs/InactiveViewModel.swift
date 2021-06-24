/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

class InactiveViewModel {
    var inactiveTabs = [Tab]()
    var normalTabs = [Tab]()
    var recentlyClosedTabs = [Tab]()
    var tabs = [Tab]()
    
    convenience init(tabs: [Tab] ) {
        self.init()
        self.tabs = tabs
    }
    
    func updateInactiveTabs() -> (inactiveTabs: [Tab], normalTabs: [Tab], recentlyClosedTabs: [Tab])  {
        let currentDate = Date()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
        let day4Old = Calendar.current.date(byAdding: .day, value: -4, to: noon) ?? Date()
        let day30Old = Calendar.current.date(byAdding: .day, value: -30, to: noon) ?? Date()
        clearAll()
        for tab in self.tabs {
            let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? 0
            let tabDate = Date.fromTimestamp(tabTimeStamp)
            if tabDate > day4Old {
                normalTabs.append(tab)
            } else if tabDate <= day4Old && tabDate >= day30Old {
                inactiveTabs.append(tab)
            } else if tabDate < day30Old {
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
