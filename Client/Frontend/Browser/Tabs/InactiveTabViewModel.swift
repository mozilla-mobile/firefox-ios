/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import Shared

enum InactiveTabStatus: String, Codable {
    case normal
    case inactive
    case recentlyClosed
    case shouldBecomeInactive
    case shouldBecomeRecentlyClosed
}

enum TabUpdateState {
    case coldStart
    case sameSession
}

struct InactiveTabModel: Codable {
    var tabWithStatus: [String: InactiveTabStatus] = [:]
    
    static let userDefaults = UserDefaults()
    
    static func save(tabModel: InactiveTabModel) {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(tabModel) {
            userDefaults.set(encoded, forKey: PrefsKeys.KeyInactiveTabsModel)
        }
    }
    
    static func get() -> InactiveTabModel? {
        if let inactiveTabsModel = userDefaults.object(forKey: PrefsKeys.KeyInactiveTabsModel) as? Data {
            do {
                let jsonDecoder = JSONDecoder()
                let inactiveTabModel = try jsonDecoder.decode(InactiveTabModel.self, from: inactiveTabsModel)
                return inactiveTabModel
            }
            catch {
                print("Error occured")
            }
        }
        return nil
    }
    
    static func clear() {
        userDefaults.removeObject(forKey: PrefsKeys.KeyInactiveTabsModel)
    }
}

class InactiveTabViewModel {
    private var inactiveTabs = [Tab]()
    private var normalTabs = [Tab]()
    private var recentlyClosedTabs = [Tab]()
    private var inactiveTabModel = InactiveTabModel()
    private var tabs = [Tab]()
    private var selectedTab: Tab?

    var filteredInactiveTabs = [Tab]()
    var filteredNormalTabs = [Tab]()
    var filteredRecentlyClosedTabs = [Tab]()
    
    func updateFilteredTabs() {
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [:]
        
        filteredNormalTabs.removeAll()
        filteredInactiveTabs.removeAll()
        filteredRecentlyClosedTabs.removeAll()
        
        for tab in self.tabs {
            if inactiveTabModel.tabWithStatus[tab.tabUUID] == .normal ||
               inactiveTabModel.tabWithStatus[tab.tabUUID] == .shouldBecomeInactive ||
               inactiveTabModel.tabWithStatus[tab.tabUUID] == .shouldBecomeRecentlyClosed {
                filteredNormalTabs.append(tab)
            } else if inactiveTabModel.tabWithStatus[tab.tabUUID] == .inactive {
                filteredInactiveTabs.append(tab)
            } else if inactiveTabModel.tabWithStatus[tab.tabUUID] == .recentlyClosed {
                filteredRecentlyClosedTabs.append(tab)
            }
        }
    }

    func updateInactiveTabs(with selectedTab: Tab?, tabs: [Tab], forceUpdate: Bool) {
        self.tabs = tabs
        self.selectedTab = selectedTab
        let currentDate = Date()
        let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate) ?? Date()
        let day4_Old = Calendar.current.date(byAdding: .day, value: -4, to: noon) ?? Date()
        let day30_Old = Calendar.current.date(byAdding: .day, value: -30, to: noon) ?? Date()
        clearAll()
        
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [:]
        let bvc = BrowserViewController.foregroundBVC()
        if bvc.updateState == .coldStart {
            // We update all tabs
            bvc.updateState = .sameSession
            
            for tab in self.tabs {
                //Append selected tab to normal tab as we don't want to remove that
                let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
                let tabDate = Date.fromTimestamp(tabTimeStamp)
                if tab == selectedTab || tabDate > day4_Old || tabTimeStamp == 0 {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = .normal
                } else if tabDate <= day4_Old && tabDate >= day30_Old {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = .inactive
                } else if tabDate < day30_Old {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = .recentlyClosed
                }
            }
            
            InactiveTabModel.save(tabModel: inactiveTabModel)
            
        } else {
            // We don't update tabs but just mark tabs that will need to be updated on cold start
            bvc.updateState = .sameSession
            
            for tab in self.tabs {
                //Append selected tab to normal tab as we don't want to remove that
                let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
                let tabDate = Date.fromTimestamp(tabTimeStamp)
                let tabType = inactiveTabModel.tabWithStatus[tab.tabUUID]
                if tabType == .shouldBecomeInactive || tabType == .shouldBecomeRecentlyClosed {
                    continue
                } else if tab == selectedTab || tabDate > day4_Old || tabTimeStamp == 0 {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = .normal
                } else if tabDate <= day4_Old && tabDate >= day30_Old {
                    // check if tab is not already inactive
                    if inactiveTabModel.tabWithStatus[tab.tabUUID] != .inactive {
                        inactiveTabModel.tabWithStatus[tab.tabUUID] = .shouldBecomeInactive
                    }
                } else if tabDate < day30_Old {
                    // check if tab is not already marked for recently closed
                    if inactiveTabModel.tabWithStatus[tab.tabUUID] != .recentlyClosed {
                        inactiveTabModel.tabWithStatus[tab.tabUUID] = .shouldBecomeRecentlyClosed
                    }
                }
            }
            
            InactiveTabModel.save(tabModel: inactiveTabModel)
        }
    }
    
    func clearAll() {
        inactiveTabs.removeAll()
        normalTabs.removeAll()
        recentlyClosedTabs.removeAll()
    }
}
