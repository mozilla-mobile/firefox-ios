// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@MainActor
final class TabsSectionManager {
    struct UX {
        static let cellAbsoluteHeight: CGFloat = 200
        static let cardSpacing: CGFloat = 16
        static let experimentCardSpacing: CGFloat = 52
        static let experimentA11yCardSpacing: CGFloat = 72
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25
        static let verticalInset: CGFloat = 20
        static let experimentTitleHeight: CGFloat = 20
        static let experimentCellPortraitAspectRatio: CGFloat = 1.4
        static let experimentCellLandscapeAspectRatio: CGFloat = 0.67
        static let regularCellEstimatedWidth: CGFloat = 250
        static let compactCellEstimatedWidth: CGFloat = 170
        static let minNumberOfCellsPerRow = 2
        static let expandedPhoneNumberOfCellsPerRow = 3
    }

    static func leadingInset(traitCollection: UITraitCollection) -> CGFloat {
        // Handles multitasking on iPad
        return usesRegularLayout(traitCollection) ? UX.iPadInset : UX.standardInset
    }

    /// Regular in both dimensions: iPad, or an expanded foldable phone. Excludes large phones in landscape.
    private static func usesRegularLayout(_ traitCollection: UITraitCollection) -> Bool {
        return traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular
    }

    private func cellEstimatedWidth(for traitCollection: UITraitCollection) -> CGFloat {
        return TabsSectionManager.usesRegularLayout(traitCollection)
            ? UX.regularCellEstimatedWidth
            : UX.compactCellEstimatedWidth
    }

    func numberOfCellsPerRow(for layoutEnvironment: NSCollectionLayoutEnvironment) -> Int {
        let traitCollection = layoutEnvironment.traitCollection
        if traitCollection.userInterfaceIdiom == .phone, TabsSectionManager.usesRegularLayout(traitCollection) {
            return UX.expandedPhoneNumberOfCellsPerRow
        }

        let availableWidth = layoutEnvironment.container.effectiveContentSize.width
        let maxNumberOfCellsPerRow = Int(availableWidth / cellEstimatedWidth(for: traitCollection))

        // maxNumberOfCellsPerRow returns 1 on smaller screen sizes which is inconvenient to scroll through
        // so here we check we have 2 cells per row at minimum.
        return max(maxNumberOfCellsPerRow, UX.minNumberOfCellsPerRow)
    }

    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let cellEstimatedWidth = self.cellEstimatedWidth(for: layoutEnvironment.traitCollection)
        let numberOfCellsPerRow = self.numberOfCellsPerRow(for: layoutEnvironment)

        let cellHeight = UX.cellAbsoluteHeight
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .estimated(cellEstimatedWidth),
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
        guard !TabsSectionManager.usesRegularLayout(layoutEnvironment.traitCollection) else {
            return experimentLayoutSectionIpad(layoutEnvironment)
        }

        let numberOfCellsPerRow = self.numberOfCellsPerRow(for: layoutEnvironment)

        let cellHeight = UX.cellAbsoluteHeight
        let itemWidth: CGFloat = 1.0 / CGFloat(numberOfCellsPerRow)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(cellHeight)
        )

        let titleSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(UX.experimentTitleHeight)
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

    // MARK: - iPad experiment layout

    /// Uses aspect ratio math to derive cell height from actual cell width so that portrait
    /// gets taller cells and landscape gets shorter cells
    private func experimentLayoutSectionIpad(
        _ layoutEnvironment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let availableWidth = layoutEnvironment.container.effectiveContentSize.width
        let availableHeight = layoutEnvironment.container.effectiveContentSize.height
        let numberOfCellsPerRow = self.numberOfCellsPerRow(for: layoutEnvironment)

        let horizontalInset = TabsSectionManager.leadingInset(traitCollection: layoutEnvironment.traitCollection)
        let totalSpacing = CGFloat(numberOfCellsPerRow - 1) * UX.cardSpacing
        let totalHorizontalInset = horizontalInset * 2
        let usableWidth = availableWidth - totalHorizontalInset - totalSpacing
        let cellWidth = usableWidth / CGFloat(numberOfCellsPerRow)
        let aspectRatio = availableWidth > availableHeight
                            ? UX.experimentCellLandscapeAspectRatio
                            : UX.experimentCellPortraitAspectRatio
        let cellHeight = (cellWidth * aspectRatio).rounded()
        let itemWidth: CGFloat = 1.0 / CGFloat(numberOfCellsPerRow)

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(itemWidth),
            heightDimension: .absolute(cellHeight)
        )

        let titleSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(UX.experimentTitleHeight)
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
