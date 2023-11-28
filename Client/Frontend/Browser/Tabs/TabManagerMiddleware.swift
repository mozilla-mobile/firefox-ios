// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

class TabManagerMiddleware {
    var tabManager: TabManager
    var inactiveTabs = [InactiveTabsModel]()
    var selectedPanel: TabTrayPanelType = .tabs

    init(tabManager: TabManager = AppContainer.shared.resolve()) {
        self.tabManager = tabManager
    }

    lazy var tabsPanelProvider: Middleware<AppState> = { state, action in
        switch action {
        case TabTrayAction.tabTrayDidLoad(let panelType):
            let tabTrayModel = self.getTabTrayModel(for: panelType)
            store.dispatch(TabTrayAction.didLoadTabTray(tabTrayModel))

        case TabPanelAction.tabPanelDidLoad(let isPrivate):
            let tabState = self.getTabsDisplayModel(for: isPrivate)
            store.dispatch(TabPanelAction.didLoadTabPanel(tabState))

        case TabTrayAction.changePanel(let panelType):
            let isPrivate = panelType == TabTrayPanelType.privateTabs
            let tabState = self.getTabsDisplayModel(for: isPrivate)
            store.dispatch(TabPanelAction.didLoadTabPanel(tabState))

        case TabPanelAction.addNewTab(let isPrivate):
            self.addNewTab(isPrivate)
            let tabs = self.refreshTabs()
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

        case TabPanelAction.moveTab(let originIndex, let destinationIndex):
            self.moveTab(from: originIndex, to: destinationIndex)
            let tabs = self.refreshTabs()
            store.dispatch(TabPanelAction.refreshTab(tabs))

        case TabPanelAction.closeTab(let index):
            self.closeTab(for: index)
            let tabs = self.refreshTabs()
            store.dispatch(TabPanelAction.refreshTab(tabs))

        case TabPanelAction.closeAllTabs:
            self.closeAllTabs()
            let tabs = self.refreshTabs()
            store.dispatch(TabPanelAction.refreshTab(tabs))

        case TabPanelAction.closeAllInactiveTabs:
            self.closeAllInactiveTabs()
            store.dispatch(TabPanelAction.refreshInactiveTabs(self.inactiveTabs))

        case TabPanelAction.closeInactiveTabs(let index):
            self.closeInactiveTab(for: index)
            store.dispatch(TabPanelAction.refreshInactiveTabs(self.inactiveTabs))

        case TabPanelAction.learnMorePrivateMode:
            self.didTapLearnMoreAboutPrivate()
            let tabs = self.refreshTabs()
            store.dispatch(TabPanelAction.refreshTab(tabs))
            store.dispatch(TabTrayAction.dismissTabTray)

//        case ActiveScreensStateAction.closeScreen(.tabsTray):
//            self.tabs.removeAll()
        default:
            break
        }
    }

    func getTabTrayModel(for panelType: TabTrayPanelType) -> TabTrayModel {
        selectedPanel = panelType

        let isPrivate = panelType == .privateTabs
        let tabsCount = refreshTabs().count
        return TabTrayModel(isPrivateMode: isPrivate,
                            selectedPanel: panelType,
                            normalTabsCount: "\(tabsCount)")
    }

    func getTabsDisplayModel(for isPrivate: Bool) -> TabDisplayModel {
        let tabs = refreshTabs()
        let isInactiveTabsExpanded = !isPrivate && !inactiveTabs.isEmpty
        let tabDisplayModel = TabDisplayModel(isPrivateMode: isPrivate,
                                              tabs: tabs,
                                              inactiveTabs: inactiveTabs,
                                              isInactiveTabsExpanded: isInactiveTabsExpanded)
        return tabDisplayModel
    }

    private func refreshTabs() -> [TabModel] {
        var tabs = [TabModel]()
        let tabManagerTabs = tabManager.tabs
        tabManagerTabs.forEach { tab in
            print("YRD tab displayTitle \(tab.displayTitle)")
            let tabModel = TabModel(tabUUID: tab.tabUUID,
                                    isSelected: false,
                                    isPrivate: tab.isPrivate,
                                    isFxHomeTab: tab.isFxHomeTab,
                                    tabTitle: tab.displayTitle,
                                    url: tab.url,
                                    screenshot: tab.screenshot,
                                    hasHomeScreenshot: tab.hasHomeScreenshot,
                                    margin: 0)
            tabs.append(tabModel)
        }

        return tabs
    }

    private func addNewTab(_ isPrivate: Bool) {
        // TODO: Add a guard to check if is dragging
        // TODO: Add request
        let tab = tabManager.addTab(nil, isPrivate: isPrivate)
        tabManager.selectTab(tab)
    }

    private func moveTab(from originIndex: Int, to destinationIndex: Int) {
        tabManager.moveTab(isPrivate: false, fromIndex: originIndex, toIndex: destinationIndex)
    }

    private func closeTab(for index: Int) {
        let tabs = refreshTabs()
        guard let tab = tabManager.getTabForUUID(uuid: tabs[index].tabUUID) else { return }
        tabManager.removeTab(tab)
    }

    private func closeAllTabs() {
        let tabs = refreshTabs()
        tabs.forEach { tabModel in
            if let tab = tabManager.getTabForUUID(uuid: tabModel.tabUUID) {
                tabManager.removeTab(tab)
            }
        }
        inactiveTabs.removeAll()
    }

    private func closeAllInactiveTabs() {
        inactiveTabs.removeAll()
    }

    private func closeInactiveTab(for index: Int) {
        inactiveTabs.remove(at: index)
    }

    private func didTapLearnMoreAboutPrivate() {
        addNewTab(true)
    }

    // MARK: Mock helpers remove after middleware is working
//    func getMockTabsDisplayModel(for isPrivate: Bool) -> TabDisplayModel {
//        for index in 0...2 {
//            let emptyTab = tabManager.addTab(nil, afterTab: nil, isPrivate: isPrivate)
//            let cellState = TabModel.emptyTabState(tabUUID: emptyTab.tabUUID, title: "Tab \(index)")
//            tabs.append(cellState)
//        }
//
//        if !isPrivate {
//            inactiveTabs = [InactiveTabsModel(url: "Tab1"),
//                            InactiveTabsModel(url: "Tab2"),
//                            InactiveTabsModel(url: "Tab3")]
//        } else {
//            inactiveTabs = [InactiveTabsModel]()
//        }
//
//        let isInactiveTabsExpanded = !isPrivate && !inactiveTabs.isEmpty
//        
//        return TabDisplayModel(isPrivateMode: isPrivate,
//                               tabs: tabs,
//                               inactiveTabs: inactiveTabs,
//                               isInactiveTabsExpanded: isInactiveTabsExpanded)
//    }

    private func resetMock() {
        closeAllTabs()
    }
}
