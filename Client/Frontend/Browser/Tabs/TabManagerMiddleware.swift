// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

class TabsPanelMiddleware {
    var tabs = [TabCellState]()
    var inactiveTabs = [String]()

    init() {}

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case TabTrayAction.tabTrayDidLoad(let panelType):
            let tabsState = self.getMockData(for: panelType)
            DispatchQueue.main.async {
                store.dispatch(TabTrayAction.didLoadTabData(tabsState))
            }
        case TabTrayAction.changePanel(let panelType):
            let tabsState = self.getMockData(for: panelType)
            DispatchQueue.main.async {
                store.dispatch(TabTrayAction.didLoadTabData(tabsState))
            }
        default:
            break
        }
    }

    func getMockData(for panelType: TabTrayPanelType) -> TabTrayState {
        guard panelType != .syncedTabs else { return TabTrayState() }

        for index in 0...2 {
            let cellState = TabCellState.emptyTabState(title: "Tab \(index)")
            tabs.append(cellState)
        }

        let isPrivate = panelType == .privateTabs
        inactiveTabs =  !isPrivate ? ["Tab1", "Tab2", "Tab3"] : [String]()

        return TabTrayState(isPrivateMode: isPrivate,
                            selectedPanel: .tabs,
                            tabs: tabs,
                            remoteTabsState: nil,
                            normalTabsCount: "\(tabs.count)",
                            inactiveTabs: inactiveTabs)
    }
}
