// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

typealias HomepageSection = HomepageDiffableDataSource.HomeSection
typealias HomepageItem = HomepageDiffableDataSource.HomeItem

/// Holds the data source configuration for the new homepage as part of the rebuild project
final class HomepageDiffableDataSource:
    UICollectionViewDiffableDataSource<HomepageSection, HomepageItem> {
    enum HomeSection: Int, Hashable {
        case header
        case topSites
        case pocket
    }

    enum HomeItem: Hashable {
        case header
    }

    func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<HomeSection, HomeItem>()

        snapshot.appendSections([.header, .topSites, .pocket])
        snapshot.appendItems([.header], toSection: .header)
        snapshot.appendItems([], toSection: .topSites)
        snapshot.appendItems([], toSection: .pocket)

        apply(snapshot, animatingDifferences: true)
    }
}
