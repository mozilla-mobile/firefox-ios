// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TabsSectionManager: FeatureFlaggable {
    struct UX {
        // On iPad we can set to have bigger tabs, on iPhone we need smaller ones
        static let cellEstimatedWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 170
        static let cellAbsoluteHeight: CGFloat = 200
        static let cardSpacing: CGFloat = 16
        static let experimentCardSpacing: CGFloat = 40
        static let experimentA11yCardSpacing: CGFloat = 72
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25
        static let verticalInset: CGFloat = 20
        static let experimentEstimatedTitleHeight: CGFloat = 20
    }

    static func leadingInset(traitCollection: UITraitCollection,
                             interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> CGFloat {
        guard interfaceIdiom != .phone else { return UX.standardInset }

        // Handles multitasking on iPad
        return traitCollection.horizontalSizeClass == .regular ? UX.iPadInset : UX.standardInset
    }

    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let availableWidth = layoutEnvironment.container.effectiveContentSize.width
        let maxNumberOfCellsPerRow = Int(availableWidth / UX.cellEstimatedWidth)
        let minNumberOfCellsPerRow = 2

        // maxNumberOfCellsPerRow returns 1 on smaller screen sizes which is inconvenient to scroll through
        // so here we check we have 2 cells per row at minimum.
        let numberOfCellsPerRow = maxNumberOfCellsPerRow < minNumberOfCellsPerRow
                                    ? minNumberOfCellsPerRow
                                    : maxNumberOfCellsPerRow

        let cellHeight = UX.cellAbsoluteHeight
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(UX.cellEstimatedWidth),
            heightDimension: .absolute(cellHeight)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(cellHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: numberOfCellsPerRow)
        group.interItemSpacing = .fixed(UX.cardSpacing)
        let section = NSCollectionLayoutSection(group: group)

        let horizontalInset = TabsSectionManager.leadingInset(traitCollection: layoutEnvironment.traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                        leading: horizontalInset,
                                                        bottom: UX.verticalInset,
                                                        trailing: horizontalInset)
        section.interGroupSpacing = UX.cardSpacing

        return section
    }

    func experimentLayoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let availableWidth = layoutEnvironment.container.effectiveContentSize.width
        let maxNumberOfCellsPerRow = Int(availableWidth / UX.cellEstimatedWidth)
        let minNumberOfCellsPerRow = 2

        // maxNumberOfCellsPerRow returns 1 on smaller screen sizes which is inconvenient to scroll through
        // so here we check we have 2 cells per row at minimum.
        let numberOfCellsPerRow = maxNumberOfCellsPerRow < minNumberOfCellsPerRow
                                    ? minNumberOfCellsPerRow
                                    : maxNumberOfCellsPerRow

        let cellHeight: CGFloat = UX.cellAbsoluteHeight
        let itemWidth: CGFloat = 1.0 / CGFloat(numberOfCellsPerRow)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(cellHeight)
        )

        let titleSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(UX.experimentEstimatedTitleHeight)
        )

        let titleSupplementary = NSCollectionLayoutSupplementaryItem(
            layoutSize: titleSize,
            elementKind: TabTitleSupplementaryView.cellIdentifier,
            containerAnchor: NSCollectionLayoutAnchor(edges: [.bottom])
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [titleSupplementary])

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(cellHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: numberOfCellsPerRow)
        group.interItemSpacing = .fixed(UX.cardSpacing)

        let section = NSCollectionLayoutSection(group: group)

        let isAccessibilitySize = layoutEnvironment.traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let horizontalInset = TabsSectionManager.leadingInset(traitCollection: layoutEnvironment.traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.verticalInset,
            leading: horizontalInset,
            bottom: isAccessibilitySize ? UX.experimentA11yCardSpacing : UX.experimentCardSpacing,
            trailing: horizontalInset
        )
        section.interGroupSpacing = isAccessibilitySize ? UX.experimentA11yCardSpacing : UX.experimentCardSpacing

        return section
    }
}
