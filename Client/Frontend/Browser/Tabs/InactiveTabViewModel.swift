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
    var tabWithStatus: [String: [InactiveTabStatus]] = [String: [InactiveTabStatus]]()
    
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
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [String: [InactiveTabStatus]]()
        
        filteredNormalTabs.removeAll()
        filteredInactiveTabs.removeAll()
        filteredRecentlyClosedTabs.removeAll()
        
        for tab in self.tabs {
            let status = inactiveTabModel.tabWithStatus[tab.tabUUID]
            if status == nil {
                filteredNormalTabs.append(tab)
            } else if let status = status, status.count == 1 {
                if status.last == .inactive {
                    filteredInactiveTabs.append(tab)
                } else if status.last == .normal {
                    filteredNormalTabs.append(tab)
                } else if status.last == .recentlyClosed {
                    filteredRecentlyClosedTabs.append(tab)
                }
            } else if let status = status, status.count > 1 {
                let count = status.count
                let previousStatus = status[count - 2]
                if previousStatus == .inactive {
                    filteredInactiveTabs.append(tab)
                } else if previousStatus == .normal {
                    filteredNormalTabs.append(tab)
                } else if previousStatus == .recentlyClosed {
                    filteredRecentlyClosedTabs.append(tab)
                }
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
        
        inactiveTabModel.tabWithStatus = InactiveTabModel.get()?.tabWithStatus ?? [String: [InactiveTabStatus]]()
        let bvc = BrowserViewController.foregroundBVC()
        if bvc.updateState == .coldStart {
            // We update all tabs
            bvc.updateState = .sameSession
            inactiveTabModel.tabWithStatus = [String: [InactiveTabStatus]]()
            for tab in self.tabs {
                //Append selected tab to normal tab as we don't want to remove that
                let tabTimeStamp = tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? tab.firstCreatedTime ?? 0
                let tabDate = Date.fromTimestamp(tabTimeStamp)
                
                if inactiveTabModel.tabWithStatus[tab.tabUUID] == nil {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = [InactiveTabStatus]()
                }
                
                if tab == selectedTab || tabDate > day4_Old || tabTimeStamp == 0 {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.append(.normal)
                } else if tabDate <= day4_Old && tabDate >= day30_Old {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.append(.inactive)
                } else if tabDate < day30_Old {
                    inactiveTabModel.tabWithStatus[tab.tabUUID]?.append(.recentlyClosed)
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
                
                if inactiveTabModel.tabWithStatus[tab.tabUUID] == nil {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = [InactiveTabStatus]()
                }
                
                let tabType = inactiveTabModel.tabWithStatus[tab.tabUUID]
                if tab == selectedTab {
                    inactiveTabModel.tabWithStatus[tab.tabUUID] = [.normal]
                } else if tabType?.last == .shouldBecomeInactive || tabType?.last == .shouldBecomeRecentlyClosed {
                    continue
                } else if tabDate > day4_Old || tabTimeStamp == 0 {
                    if inactiveTabModel.tabWithStatus[tab.tabUUID]?.last != .normal {
                        inactiveTabModel.tabWithStatus[tab.tabUUID] = [.normal]
                    }
                } else if tabDate <= day4_Old && tabDate >= day30_Old {
                    // check if tab is not already inactive
                    if inactiveTabModel.tabWithStatus[tab.tabUUID]?.last != .inactive {
                        inactiveTabModel.tabWithStatus[tab.tabUUID]?.append(.shouldBecomeInactive)
                    }
                } else if tabDate < day30_Old {
                    // check if tab is not already marked for recently closed
                    if inactiveTabModel.tabWithStatus[tab.tabUUID]?.last != .recentlyClosed {
                        inactiveTabModel.tabWithStatus[tab.tabUUID]?.append(.shouldBecomeRecentlyClosed)
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
