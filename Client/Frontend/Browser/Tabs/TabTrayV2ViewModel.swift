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
    fileprivate var dataStore: [TabSection: WeakList<Tab>] = [ .today: WeakList<Tab>(),
                                                   .yesterday: WeakList<Tab>(),
                                                   .lastWeek: WeakList<Tab>(),
                                                   .older: WeakList<Tab>()]
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
            dataStore[section]?.insert(tab)
        }
    
        viewController.tableView.reloadData()
    }

    func timestampToSection(_ tab: Tab) -> TabSection {
        let tabDate = Date.fromTimestamp(tab.lastExecutedTime ?? Date.now())
        let now = Date()

        if tabDate <= Date().lastWeek {
            return .older
        } else if tabDate <= Date.yesterday {
            return .lastWeek
        } else if tabDate <= now {
            return .yesterday
        } else if tabDate == now {
            return .today
        } else {
            return .older
        }
    }
    
    // The user has tapped the close button or has swiped away the cell
    func removeTab(forIndex index: IndexPath) {
        guard let section = TabSection(rawValue: index.section), let tab = dataStore[section]?.at(index.row) else {
            return
        }
        
        tabManager.removeTabAndUpdateSelectedIndex(tab)
    }

    // When using 'Close All', hide all the tabs so they don't animate their deletion individually
    func closeAllTabs( completion: @escaping () -> Void) {
       
    }
    
    func didSelectRowAt (index: IndexPath) {
        guard let section = TabSection(rawValue: index.section), let tab = dataStore[section]?.at(index.row) else {
            return
        }
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
            let data = dataStore[section]?.at(index.row),
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
    func tabManager(_ tabManager: TabManager, didSelectedTabChange selected: Tab?, previous: Tab?, isRestoring: Bool) {

    }

    func tabManager(_ tabManager: TabManager, didAddTab tab: Tab, isRestoring: Bool) {
        
    }

    func tabManager(_ tabManager: TabManager, didRemoveTab tab: Tab, isRestoring: Bool) {
        for (section, tabs) in dataStore {
             if let removed = tabs.remove(tab) {
                viewController.tableView.deleteRows(at: [IndexPath(row: removed, section: section.rawValue)], with: .automatic)
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
