/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
    fileprivate let viewController: TabTrayV2ViewController

    private(set) var isPrivate = false

    init(viewController: TabTrayV2ViewController) {
        self.viewController = viewController
        self.tabManager = BrowserViewController.foregroundBVC().tabManager //fixme
        self.isPrivate = tabManager.selectedTab?.isPrivate ?? false
        super.init()

        tabManager.addDelegate(self)
        register(self, forTabEvents: .didLoadFavicon, .didChangeURL)

        tabManager.tabs.forEach { tab in
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
            sectionHeader = Strings.TabTrayV2TodayHeader
            date = dateFormatter.string(from: Date())
        case .yesterday:
            sectionHeader = Strings.TabTrayV2YesterdayHeader
            date = dateFormatter.string(from: Date.yesterday)
        case .lastWeek:
            sectionHeader = Strings.TabTrayV2LastWeekHeader
            date = dateIntervalFormatter.string(from: Date().lastWeek, to: Date(timeInterval: 6.0 * 24.0 * 3600.0, since: Date().lastWeek))
        case .older:
            sectionHeader = Strings.TabTrayV2OlderHeader
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
        
        tabManager.removeTabAndUpdateSelectedIndex(tab)
    }

    // When using 'Close All', hide all the tabs so they don't animate their deletion individually
    func closeAllTabs( completion: @escaping () -> Void) {
       
    }
    func closeTabsForCurrentTray() {
        viewController.hideDisplayedTabs() {
            self.tabManager.removeTabsWithUndoToast(self.dataStore.compactMap{ $0.1 }.flatMap{ $0 })
                if self.tabManager.normalTabs.count == 1, let tab = self.tabManager.normalTabs.first {
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
    
    func numberOfRowsInSection(section: Int) -> Int {
        return dataStore[TabSection(rawValue: section) ?? .today]?.count ?? 0
    }
    
    func configure(cell: TabTableViewCell, for index: IndexPath) {
        guard let section = TabSection(rawValue: index.section),
            let data = dataStore[section]?[index.row],
            let textLabel = cell.textLabel,
            let detailTextLabel = cell.detailTextLabel,
            let imageView = cell.imageView
            else { return }
        textLabel.text = data.displayTitle
        detailTextLabel.text = data.url?.baseDomain ?? " "
        imageView.image = data.screenshot
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

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) { }
    
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
