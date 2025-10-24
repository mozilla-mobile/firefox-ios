// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct StoriesFeedSectionLayoutProvider {
    struct UX {
        static let cellSize = CGSize(width: 361, height: 282)
        static let interItemSpacing: CGFloat = 16
        static let interGroupSpacing: CGFloat = 16
        static let topSectionInset: CGFloat = 10
        static let minimumSectionHorizontalInset: CGFloat = 16
        static let minimumCellsPerRow = 1
    }

    func createStoriesFeedSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize
        // For iOS 17+ we use uniform height across cells in the same group (row) which is the height of the tallest cell
        // in the group.
        // For iOS 16 and earlier, we allow the cell to grow as big as it needs to show it's content, often resulting in
        // groups of cells with uneven heights
        if #available(iOS 17.0, *) {
            itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .uniformAcrossSiblings(estimate: UX.cellSize.height)
            )
        } else {
            itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(UX.cellSize.height)
            )
        }

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(UX.cellSize.height)
        )

        let containerWidth = environment.container.effectiveContentSize.width
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: containerWidth)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: cellCount
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interItemSpacing)

        let horizontalInsets = StoriesFeedDimensionCalculator.horizontalInset(for: containerWidth, cellCount: cellCount)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topSectionInset,
            leading: horizontalInsets,
            bottom: 0,
            trailing: horizontalInsets
        )
        section.interGroupSpacing = UX.interGroupSpacing

        return section
    }
}
