// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

enum TabSection: Int, CaseIterable {
    case today
    case yesterday
    case lastWeek
    case older
}

protocol TopTabCellDelegateV2: AnyObject {
    func tabCellDidClose(_ cell: UICollectionViewCell)
}

class TabTrayV2ViewModel: NSObject {
    fileprivate var dataStore: [TabSection: [Tab]] = [ .today: Array<Tab>(),
                                                   .yesterday: Array<Tab>(),
                                                   .lastWeek: Array<Tab>(),
                                                   .older: Array<Tab>()]
    fileprivate let tabManager: TabManager
    fileprivate let viewController: ChronologicalTabsViewController
    private var isPrivate = false
    var isInPrivateMode: Bool {
        return isPrivate
    }
    var shouldShowPrivateView: Bool {
        return isPrivate && getTabs().isEmpty
    }

    init(viewController: ChronologicalTabsViewController) {
        self.viewController = viewController
        self.tabManager = BrowserViewController.foregroundBVC().tabManager
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        super.init()
        tabManager.addDelegate(self)
        register(self, forTabEvents: .didLoadFavicon, .didChangeURL)
    }
    
    // Returns tabs for the mode the current view model is in
    func getTabs() -> [Tab] {
        return self.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
    }
    
    func getTabDomainUrl(tab: Tab) -> URL? {
        guard tab.url != nil else {
            return tab.sessionData?.urls.last?.domainURL
        }
        return tab.url?.domainURL
    }
    
    func countOfNormalTabs() -> Int {
        return tabManager.normalTabs.count
    }

    func togglePrivateMode (_ toggleToOn: Bool) {
        tabManager.willSwitchTabMode(leavingPBM: self.isPrivate)
        self.isPrivate = toggleToOn ? true : false
        resetDataStoreTabs()
        let tabs = getTabs()
        let tab = mostRecentTab(inTabs: tabs) ?? tabs.last
        if let tab = tab {
            tabManager.selectTab(tab)
        } else {
            self.addTab()
        }
    }
    
    func addPrivateTab() {
        guard isPrivate && getTabs().isEmpty else {
            return
        }
        self.addTab()
        tabManager.selectTab(getTabs().last)
    }
    
    func updateTabs() {
        let tabs = getTabs()
        tabs.forEach { tab in
            let section = timestampToSection(tab)
            dataStore[section]?.insert(tab, at: 0)
        }
    
        for (section, list) in dataStore {
            let sorted = list.sorted {
                let firstTab = $0.lastExecutedTime ?? $0.sessionData?.lastUsedTime ?? 0
                let secondTab = $1.lastExecutedTime ?? $1.sessionData?.lastUsedTime ?? 0
                return firstTab > secondTab
            }
            _ = dataStore.updateValue(sorted, forKey: section)
        }
        viewController.tableView.reloadData()
    }
    
    func resetDataStoreTabs() {
        dataStore.removeAll()
        dataStore = [ .today: Array<Tab>(),
        .yesterday: Array<Tab>(),
        .lastWeek: Array<Tab>(),
        .older: Array<Tab>()]
    }
    
    func timestampToSection(_ tab: Tab) -> TabSection {
        let tabDate = Date.fromTimestamp(tab.lastExecutedTime ?? tab.sessionData?.lastUsedTime ?? Date.now())
        if tabDate.isToday() {
            return .today
        } else if tabDate.isYesterday() {
            return .yesterday
        } else if tabDate.isWithinLast7Days() {
            return .lastWeek
        } else {
            return .older
        }
    }
    
    func getSectionDateHeader(_ section: Int) -> String {
        let section = TabSection(rawValue: section)
        let sectionHeader: String
        let date: String
        let dateFormatter = DateFormatter()
        let dateIntervalFormatter = DateIntervalFormatter()
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: Locale.current.identifier)
        
        dateIntervalFormatter.dateStyle = .medium
        dateIntervalFormatter.timeStyle = .none
        dateIntervalFormatter.locale = Locale(identifier: Locale.current.identifier)
        
        switch section {
        case .today:
            sectionHeader = .TabTrayV2TodayHeader
            date = dateFormatter.string(from: Date())
        case .yesterday:
            sectionHeader = .TabTrayV2YesterdayHeader
            date = dateFormatter.string(from: Date.yesterday)
        case .lastWeek:
            sectionHeader = .TabTrayV2LastWeekHeader
            date = dateIntervalFormatter.string(from: Date().lastWeek, to: Date(timeInterval: 6.0 * 24.0 * 3600.0, since: Date().lastWeek))
        case .older:
            sectionHeader = .TabTrayV2OlderHeader
            date = ""
        default:
            sectionHeader = ""
            date = ""
        }
        
        return (sectionHeader + (!date.isEmpty ? " — " : " ") + date).uppercased()
    }
    
    // The user has tapped the close button or has swiped away the cell
    func removeTab(forIndex index: IndexPath) {
        guard let section = TabSection(rawValue: index.section), let tab = dataStore[section]?[index.row] else {
            return
        }

        let tabCount = self.getTabs().count
        tabManager.removeTab(tab)
        NotificationCenter.default.post(name: .TabClosed, object: nil)
        if tabCount == 1 && self.getTabs().count == 1 {
            // The last tab was removed. Dismiss the tab tray
            self.viewController.dismissTabTray()
        }
    }

    func closeTabsForCurrentTray() {
        viewController.hideDisplayedTabs() {
            let maxTabs = 100
            let tabs = self.dataStore.compactMap { $0.1 }.flatMap { $0 }
            if tabs.count >= maxTabs {
                self.tabManager.removeTabsAndAddNormalTab(tabs)
            } else {
                self.tabManager.removeTabsWithToast(tabs)
            }
            
            if self.getTabs().count == 1, let tab = self.getTabs().first {
            self.tabManager.selectTab(tab)
                self.viewController.dismissTabTray()
            }
        }
    }
    
    func didSelectRowAt (index: IndexPath) {
        guard let section = TabSection(rawValue: index.section), let tab = dataStore[section]?[index.row] else {
            return
        }
        tab.lastExecutedTime = Date.now()
        selectTab(tab)
    }
    
    func selectTab(_ tab: Tab) {
        tabManager.selectTab(tab)
    }
    
    func addTab(_ request: URLRequest! = nil) {
        tabManager.selectTab(tabManager.addTab(request, isPrivate: isPrivate))
    }
    
    func numberOfSections() -> Int {
        return TabSection.allCases.count
    }

    func getTab(forIndex index: IndexPath) -> Tab? {
        guard let section = TabSection(rawValue: index.section), let tab = dataStore[section]?[index.row] else {
            return nil
        }
        return tab
    }
    
    func numberOfRowsInSection(section: Int) -> Int {
        return dataStore[TabSection(rawValue: section) ?? .today]?.count ?? 0
    }
    
    func configure(cell: TabTableViewCell, for index: IndexPath) {
        guard let section = TabSection(rawValue: index.section),
              let tab = dataStore[section]?[index.row] else { return }

        let baseDomain = tab.sessionData?.urls.last?.baseDomain ?? tab.url?.baseDomain
        let urlLabel = baseDomain != nil ? baseDomain!.contains("local") ? " " : baseDomain : " "
        
        // Setting default white image as screenshot
        cell.screenshotView?.image = UIColor.white.image()
        if let tabScreenshot = tab.screenshot {
            // Set proper screenshot from tab
            cell.screenshotView?.image = tabScreenshot
        } else if let domainUrl = getTabDomainUrl(tab: tab) {
            // Set Favicon from domain url when screenshot from tab is empty
            cell.screenshotView?.setImageAndBackground(forIcon: tab.displayFavicon, website: domainUrl) {}
        }
        
        cell.websiteTitle?.text = tab.displayTitle
        cell.urlLabel?.text = urlLabel
        cell.accessoryView = cell.closeButton
    }
}

extension TabTrayV2ViewModel: TabEventHandler {
    private func updateCellFor(tab: Tab, selectedTabChanged: Bool) {
        
    }

    func tab(_ tab: Tab, didLoadFavicon favicon: Favicon?, with: Data?) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }

    func tab(_ tab: Tab, didChangeURL url: URL) {
        updateCellFor(tab: tab, selectedTabChanged: false)
    }
}

extension TabTrayV2ViewModel: TabManagerDelegate {
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) { }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, placeNextToParentTab: Bool, isRestoring: Bool) { }
    
    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        for (section, tabs) in dataStore {
            if let removalIndex = tabs.firstIndex(where: { $0 === tab }) {
                dataStore[section]?.remove(at: removalIndex)
                viewController.tableView.deleteRows(at: [IndexPath(row: removalIndex, section: section.rawValue)], with: .automatic)
            }
        }
    }

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
       
    }

    func tabManagerDidAddTabs(_ tabManager: TabManager) {
       
    }

    func tabManagerDidRemoveAllTabs(_ tabManager: TabManager, toast: ButtonToast?) {
        
    }
}
