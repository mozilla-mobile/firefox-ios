// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

typealias TabDisplayViewSection = TabDisplayDiffableDataSource.TabSection
typealias TabDisplayViewItem = TabDisplayDiffableDataSource.TabItem

final class TabDisplayDiffableDataSource: UICollectionViewDiffableDataSource<TabDisplayViewSection, TabDisplayViewItem> {
    enum TabSection: Hashable {
        case tabs
    }

    enum TabItem: Hashable {
        case tab(TabModel)
    }

    func updateSnapshot(state: TabsPanelState) {
        var snapshot = NSDiffableDataSourceSnapshot<TabDisplayViewSection, TabDisplayViewItem>()
        snapshot.appendSections([.tabs])

        let tabs = state.tabs.map { TabDisplayViewItem.tab($0) }
        snapshot.appendItems(tabs, toSection: .tabs)

        apply(snapshot, animatingDifferences: true)
    }
}
