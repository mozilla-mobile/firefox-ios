// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

typealias TabDisplayViewSection = TabDisplayDiffableDataSource.TabSection
typealias TabDisplayItem = TabDisplayDiffableDataSource.TabItem

final class TabDisplayDiffableDataSource: UICollectionViewDiffableDataSource<TabDisplayViewSection, TabDisplayItem> {
    enum TabSection: Int, CaseIterable {
        case inactiveTabs
        case tabs
    }

    enum TabItem: Hashable {
        case inactiveTab(InactiveTabsModel)
        case tab(TabModel)
    }

    func updateSnapshot(state: TabsPanelState) {
        var snapshot = NSDiffableDataSourceSnapshot<TabDisplayViewSection, TabDisplayItem>()

        snapshot.appendSections([.inactiveTabs, .tabs])

        // reloading .inactiveTabs is necessary to animate the caret moving when we show or hide inactive tabs
        snapshot.reloadSections([.inactiveTabs])

        if state.isInactiveTabsExpanded {
            let inactiveTabs = state.inactiveTabs.map { TabDisplayItem.inactiveTab($0) }
            snapshot.appendItems(inactiveTabs, toSection: .inactiveTabs)
        }

        let tabs = state.tabs.map { TabDisplayItem.tab($0) }
        snapshot.appendItems(tabs, toSection: .tabs)

        apply(snapshot, animatingDifferences: true)
    }
}
