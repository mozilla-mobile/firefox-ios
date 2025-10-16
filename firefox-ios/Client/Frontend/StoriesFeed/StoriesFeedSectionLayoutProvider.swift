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

        // Calculates the horizontal inset given the size of the container and number of cells we need to show
        static func getHorizontalInsets(for containerWidth: CGFloat, cellCount: Int) -> CGFloat {
            let totalCellWidth = UX.cellSize.width * CGFloat(cellCount)
            let totalCellSpacing = CGFloat(cellCount) * UX.interItemSpacing
            return max(UX.minimumSectionHorizontalInset,
                       (containerWidth - totalCellWidth - totalCellSpacing + UX.interItemSpacing) / 2)
        }
    }

    func createStoriesFeedSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let itemSize: NSCollectionLayoutSize
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
        let cellCount = numberOfCellsThatFit(in: containerWidth)

        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: cellCount
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interItemSpacing)

        let horizontalInsets = UX.getHorizontalInsets(for: containerWidth, cellCount: cellCount)
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

    // Calculates the number of cells that fit given a container's width, including spacing between items and minimum
    // horizontal insets
    private func numberOfCellsThatFit(in containerWidth: CGFloat) -> Int {
        // # of cells that would fit in container
        let cellsPerRow = containerWidth / UX.cellSize.width
        // Amount of space used by inter-item spacing and horizontal insets
        let spacingAdjustment = (cellsPerRow > 1 ? (cellsPerRow - 1) * UX.interItemSpacing : 0) //
                                + (UX.minimumSectionHorizontalInset * 2)
        // Available container width for cells
        let adjustedContainerWidth = containerWidth - spacingAdjustment
        // Number of cells that will fit in a row, considering inter-item spacing and horizontal insets
        let adjustedCellsPerRow = Int(adjustedContainerWidth / UX.cellSize.width)
        return max(UX.minimumCellsPerRow, adjustedCellsPerRow)
    }
}
