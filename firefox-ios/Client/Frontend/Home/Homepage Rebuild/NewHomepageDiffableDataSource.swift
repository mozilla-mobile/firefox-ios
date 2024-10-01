// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

typealias HomepageSection = NewHomepageDiffableDataSource.HomeSection
typealias HomepageItem = NewHomepageDiffableDataSource.HomeItem

/// Holds the data source configuration for the new homepage as part of the rebuild project
class NewHomepageDiffableDataSource:
    UICollectionViewDiffableDataSource<HomepageSection, HomepageItem> {
    enum HomeSection: Int, Hashable {
        case header
        case topSites
        case pocket
    }

    // TODO: FXIOS-10162 Update item type depending section data
    struct HomeItem: Hashable {
        let id: UUID
        let title: String
    }

    func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        snapshot.appendSections([.header, .topSites, .pocket])

        // TODO: FXIOS-10162 Remove the dummy data and start implementing using the header section
        let items = [
            HomeItem(id: UUID(), title: "First"),
            HomeItem(id: UUID(), title: "Second"),
            HomeItem(id: UUID(), title: "Third")
        ]

        let items2 = [
            HomeItem(id: UUID(), title: "First"),
            HomeItem(id: UUID(), title: "Second"),
        ]

        let items3 = [
            HomeItem(id: UUID(), title: "First"),
        ]

        snapshot.appendItems(items, toSection: .header)
        snapshot.appendItems(items2, toSection: .topSites)
        snapshot.appendItems(items3, toSection: .pocket)

        apply(snapshot, animatingDifferences: true)
    }

    func updateHeaderSection() {
        var updatedSnapshot = snapshot()

        if !updatedSnapshot.sectionIdentifiers.contains(.header) {
            updatedSnapshot.appendSections([.header])
        }

        let currentItems = updatedSnapshot.itemIdentifiers(inSection: .header)

        updatedSnapshot.deleteItems(currentItems)

        // TODO: FXIOS-10162 Remove the dummy data and start implementing using the header section
        let newItems = [
            HomeItem(id: UUID(), title: "Fourth"),
        ]

        updatedSnapshot.appendItems(newItems, toSection: .header)

        apply(updatedSnapshot, animatingDifferences: true)
    }
}
