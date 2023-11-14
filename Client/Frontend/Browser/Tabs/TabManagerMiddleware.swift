// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

class TabsPanelMiddleware {
    var tabs = [TabCellState]()
    var inactiveTabs = [String]()
    var selectedPanel: TabTrayPanelType = .tabs

    init() {}

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case TabTrayAction.tabTrayDidLoad(let panelType):
            let tabsState = self.getMockData(for: panelType)
            store.dispatch(TabTrayAction.didLoadTabData(tabsState))
        case TabTrayAction.changePanel(let panelType):
            let tabsState = self.getMockData(for: panelType)
            store.dispatch(TabTrayAction.didLoadTabData(tabsState))
        case TabTrayAction.addNewTab(let isPrivate):
            self.addNewTab()
            store.dispatch(TabTrayAction.refreshTab(self.tabs))
        case TabTrayAction.moveTab(let originIndex, let destinationIndex):
            self.moveTab(from: originIndex, to: destinationIndex)
            store.dispatch(TabTrayAction.refreshTab(self.tabs))
        case TabTrayAction.closeTab(let index):
            self.closeTab(for: index)
            store.dispatch(TabTrayAction.refreshTab(self.tabs))
        case TabTrayAction.closeAllTabs:
            self.closeAllTabs()
            store.dispatch(TabTrayAction.refreshTab(self.tabs))
        default:
            break
        }
    }

    func getMockData(for panelType: TabTrayPanelType) -> TabTrayState {
        selectedPanel = panelType
        guard panelType != .syncedTabs else { return TabTrayState() }

        for index in 0...2 {
            let cellState = TabCellState.emptyTabState(title: "Tab \(index)")
            tabs.append(cellState)
        }

        let isPrivate = panelType == .privateTabs
        inactiveTabs =  !isPrivate ? ["Tab1", "Tab2", "Tab3"] : [String]()

        return TabTrayState(isPrivateMode: isPrivate,
                            selectedPanel: panelType,
                            tabs: tabs,
                            remoteTabsState: nil,
                            normalTabsCount: "\(tabs.count)",
                            inactiveTabs: inactiveTabs)
    }

    private func addNewTab() {
        let cellState = TabCellState.emptyTabState(title: "New tab")
        tabs.append(cellState)
    }

    private func moveTab(from originIndex: Int, to destinationIndex: Int) {
        tabs.move(fromOffsets: IndexSet(integer: originIndex), toOffset: destinationIndex)
    }

    private func closeTab(for index: Int) {
        tabs.remove(at: index)
    }

    private func closeAllTabs() {
        tabs.removeAll()
    }
}
