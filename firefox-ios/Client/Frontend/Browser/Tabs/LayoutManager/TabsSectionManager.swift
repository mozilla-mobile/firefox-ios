// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TabsSectionManager: FeatureFlaggable {
    struct UX {
        // On iPad we can set to have bigger tabs, on iPhone we need smaller ones
        static let cellEstimatedWidth: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 250 : 170
        static let cellAbsoluteHeight: CGFloat = 200
        static let experimentCellEstimatedHeight: CGFloat = 220
        static let cardSpacing: CGFloat = 16
        static let experimentCardSpacing: CGFloat = 28
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25
        static let verticalInset: CGFloat = 20
    }

    private var isTabTrayUIExperimentsEnabled: Bool {
        return featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly)
        && UIDevice.current.userInterfaceIdiom != .pad
    }

    static func leadingInset(traitCollection: UITraitCollection,
                             interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> CGFloat {
        guard interfaceIdiom != .phone else { return UX.standardInset }

        // Handles multitasking on iPad
        return traitCollection.horizontalSizeClass == .regular ? UX.iPadInset : UX.standardInset
    }

    // TODO: Laurie - This isn't right with absolute
    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let availableWidth = layoutEnvironment.container.effectiveContentSize.width
        let maxNumberOfCellsPerRow = Int(availableWidth / UX.cellEstimatedWidth)
        let numberOfCellsPerRow = max(maxNumberOfCellsPerRow, 2)

        let cellHeight: CGFloat = isTabTrayUIExperimentsEnabled ? UX.experimentCellEstimatedHeight : UX.cellAbsoluteHeight
        let itemWidth: CGFloat = 1.0 / CGFloat(numberOfCellsPerRow)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(cellHeight)
        )

        let item: NSCollectionLayoutItem
        if isTabTrayUIExperimentsEnabled {
            let titleSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(20)
            )

            let titleSupplementary = NSCollectionLayoutSupplementaryItem(
                layoutSize: titleSize,
                elementKind: TabTitleSupplementaryView.cellIdentifier,
                containerAnchor: NSCollectionLayoutAnchor(edges: [.bottom])
            )
            item = NSCollectionLayoutItem(layoutSize: itemSize, supplementaryItems: [titleSupplementary])
        } else {
            item = NSCollectionLayoutItem(layoutSize: itemSize)
        }

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(cellHeight)
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
        section.interGroupSpacing = isTabTrayUIExperimentsEnabled ? UX.experimentCardSpacing : UX.cardSpacing

        return section
    }
}
