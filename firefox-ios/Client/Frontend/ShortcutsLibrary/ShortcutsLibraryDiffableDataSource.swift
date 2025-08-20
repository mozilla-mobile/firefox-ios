// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

typealias ShortcutsLibrarySection = ShortcutsLibraryDiffableDataSource.Section
typealias ShortcutsLibraryItem = ShortcutsLibraryDiffableDataSource.Item

final class ShortcutsLibraryDiffableDataSource:
    UICollectionViewDiffableDataSource<ShortcutsLibrarySection, ShortcutsLibraryItem> {
    // MARK: - Enums
    enum Section: Hashable {
        case shortcuts
    }

    enum Item: Hashable {
        case shortcut(TopSiteConfiguration)

        static var cellTypes: [ReusableCell.Type] {
            return [
                TopSiteCell.self,
            ]
        }
    }

    // MARK: - Private constants
    private let maxShortcutsToShow = 16

    func updateSnapshot(state: ShortcutsLibraryState) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

        if let shortcuts = getShortcuts(with: state) {
            snapshot.appendSections([.shortcuts])
            snapshot.appendItems(shortcuts, toSection: .shortcuts)
        }

        apply(snapshot, animatingDifferences: false)
    }

    private func getShortcuts(with state: ShortcutsLibraryState) -> [ShortcutsLibraryDiffableDataSource.Item]? {
        let shortcuts: [Item] = state.shortcuts.compactMap { .shortcut($0) }
        guard !shortcuts.isEmpty else { return nil }
        return Array(shortcuts.prefix(maxShortcutsToShow))
    }
}
