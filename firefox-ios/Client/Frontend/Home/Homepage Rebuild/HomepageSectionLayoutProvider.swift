// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Holds section layout logic for the new homepage as part of the rebuild project
final class HomepageSectionLayoutProvider {
    struct UX {
        static let standardInset: CGFloat = 16
        static let standardSpacing: CGFloat = 16
        static let interGroupSpacing: CGFloat = 8
        static let iPadInset: CGFloat = 50
        static let spacingBetweenSections: CGFloat = 62

        static func leadingInset(
            traitCollection: UITraitCollection,
            interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        ) -> CGFloat {
            guard interfaceIdiom != .phone else { return standardInset }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadInset : standardInset
        }

        struct HeaderConstants {
            static let bottomSpacing: CGFloat = 30
        }

        struct PocketConstants {
            static let cellHeight: CGFloat = 112
            static let cellWidth: CGFloat = 350
            static let numberOfItemsInColumn = 3
            static let fractionalWidthiPhonePortrait: CGFloat = 0.90
            static let fractionalWidthiPhoneLandscape: CGFloat = 0.46
            static let headerFooterHeight: CGFloat = 34
            static let interItemSpacing = NSCollectionLayoutSpacing.fixed(8)

            // The dimension of a cell
            // Fractions for iPhone to only show a slight portion of the next column
            static func getWidthDimension(device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
                                          isLandscape: Bool = UIWindow.isLandscape) -> NSCollectionLayoutDimension {
                if device == .pad {
                    return .absolute(UX.PocketConstants.cellWidth)
                } else if isLandscape {
                    return .fractionalWidth(UX.PocketConstants.fractionalWidthiPhoneLandscape)
                } else {
                    return .fractionalWidth(UX.PocketConstants.fractionalWidthiPhonePortrait)
                }
            }
        }

        struct TopSitesConstants {
            static let cellEstimatedSize = CGSize(width: 85, height: 94)
            static let minCards = 4
        }
    }

    private var logger: Logger

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let section = HomepageSection(rawValue: sectionIndex) else {
                self.logger.log(
                    "Section should not have been nil, something went wrong",
                    level: .fatal,
                    category: .homepage
                )
                return nil
            }
            return self.createLayoutSection(
                    for: section,
                    with: environment.traitCollection,
                    size: environment.container.effectiveContentSize
                )
        }
    }

    private func createLayoutSection(
        for section: HomepageSection,
        with traitCollection: UITraitCollection,
        size: CGSize
    ) -> NSCollectionLayoutSection {
        switch section {
        case .header:
            return createHeaderSectionLayout(for: traitCollection)
        case .topSites:
            return createTopSitesSectionLayout(
                for: traitCollection,
                availableWidth: size.width
            )
        case .pocket:
            return createPocketSectionLayout(for: traitCollection)
        case .customizeHomepage:
            return createCustomizeSectionLayout(for: traitCollection)
        }
    }

    private func createHeaderSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.standardInset,
            leading: leadingInset,
            bottom: UX.HeaderConstants.bottomSpacing,
            trailing: leadingInset)

        return section
    }

    private func createPocketSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.PocketConstants.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: UX.PocketConstants.getWidthDimension(),
            heightDimension: .estimated(UX.PocketConstants.cellHeight)
        )

        let subItems = Array(repeating: item, count: UX.PocketConstants.numberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = UX.PocketConstants.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: 0,
            bottom: 0,
            trailing: UX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                      heightDimension: .estimated(UX.PocketConstants.headerFooterHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize,
                                                                 elementKind: UICollectionView.elementKindSectionFooter,
                                                                 alignment: .bottom)
        section.boundarySupplementaryItems = [header, footer]

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: UX.standardInset,
                                                        trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    func createTopSitesSectionLayout(
        for traitCollection: UITraitCollection,
        availableWidth: CGFloat
    ) -> NSCollectionLayoutSection {
        let numberOfTilesPerRow = TopSitesDimensionImplementation().getNumberOfTilesPerRow(
            availableWidth: availableWidth,
            leadingInset: UX.leadingInset(
                traitCollection: traitCollection
            ),
            cellWidth: UX.TopSitesConstants.cellEstimatedSize.width
        )

        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / CGFloat(numberOfTilesPerRow)),
            heightDimension: .estimated(UX.TopSitesConstants.cellEstimatedSize.height)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.TopSitesConstants.cellEstimatedSize.height)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: numberOfTilesPerRow
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.standardSpacing)
        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: leadingInset,
            bottom: UX.spacingBetweenSections - UX.interGroupSpacing,
            trailing: leadingInset
        )
        section.interGroupSpacing = UX.standardSpacing

        return section
    }

    private func createCustomizeSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let horizontalInsets = UX.leadingInset(traitCollection: traitCollection)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.spacingBetweenSections,
            leading: horizontalInsets,
            bottom: UX.spacingBetweenSections,
            trailing: horizontalInsets)
        return section
    }
}
