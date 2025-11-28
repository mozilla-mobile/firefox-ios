// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
struct TopSitesSectionLayoutProvider {
    struct UX {
        static let estimatedCellSize = CGSize(width: 85, height: 94)
        static let minCards = 4
    }

    @MainActor
    static func createTopSitesSectionLayout(
        for traitCollection: UITraitCollection,
        numberOfTilesPerRow: Int
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(numberOfTilesPerRow)),
            heightDimension: .estimated(UX.estimatedCellSize.height)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.estimatedCellSize.height)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: numberOfTilesPerRow
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(HomepageSectionLayoutProvider.UX.standardSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = HomepageSectionLayoutProvider.UX.standardSpacing
        let leadingInset = HomepageSectionLayoutProvider.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets.leading = leadingInset
        section.contentInsets.trailing = leadingInset

        return section
    }
}
