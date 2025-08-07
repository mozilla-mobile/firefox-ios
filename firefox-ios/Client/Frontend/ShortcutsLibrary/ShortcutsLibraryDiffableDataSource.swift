// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

typealias ShortcutsLibrarySection = ShortcutsLibraryDiffableDataSource.Section
typealias ShortcutsLibraryItem = ShortcutsLibraryDiffableDataSource.Item

final class ShortcutsLibraryDiffableDataSource:
    UICollectionViewDiffableDataSource<ShortcutsLibrarySection, ShortcutsLibraryItem> {
    enum Section: Hashable {
        case shortcuts
    }

    enum Item: Hashable {
        case shortcuts(TopSiteConfiguration)
    }

    func updateSnapshot(state: ShortcutsLibraryState) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

//        snapshot.appendSections([.shortcuts])
//        snapshot.appendItems([.shortcuts], toSection: .shortcuts)

        apply(snapshot, animatingDifferences: false)
    }
}
