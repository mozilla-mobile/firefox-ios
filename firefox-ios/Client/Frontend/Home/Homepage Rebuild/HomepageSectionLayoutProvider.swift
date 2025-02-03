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
        static let standardSingleItemHeight: CGFloat = 100

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

        struct MessageCardConstants {
            static let height: CGFloat = 180
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

        struct JumpBackInConstants {
            static let itemHeight: CGFloat = 112
        }

        struct BookmarksConstants {
            static let cellHeight: CGFloat = 110
            static let cellWidth: CGFloat = 150
        }
    }

    private var logger: Logger
    private var windowUUID: WindowUUID

    init(windowUUID: WindowUUID, logger: Logger = DefaultLogger.shared) {
        self.windowUUID = windowUUID
        self.logger = logger
    }

    func createLayoutSection(
        for section: HomepageSection,
        with traitCollection: UITraitCollection
    ) -> NSCollectionLayoutSection {
        switch section {
        case .header:
            return createSingleItemSectionLayout(
                for: traitCollection,
                topInsets: UX.standardInset,
                bottomInsets: UX.HeaderConstants.bottomSpacing
            )
        case .messageCard:
            return createSingleItemSectionLayout(
                for: traitCollection,
                itemHeight: UX.MessageCardConstants.height,
                bottomInsets: UX.spacingBetweenSections
            )
        case .topSites(let numberOfTilesPerRow):
            return createTopSitesSectionLayout(
                for: traitCollection,
                numberOfTilesPerRow: numberOfTilesPerRow
            )
        case .jumpBackIn:
            return createJumpBackInSectionLayout(for: traitCollection)
        case .pocket:
            return createPocketSectionLayout(for: traitCollection)
        case .customizeHomepage:
            return createSingleItemSectionLayout(
                for: traitCollection,
                topInsets: UX.spacingBetweenSections,
                bottomInsets: UX.spacingBetweenSections
            )
        case .bookmarks:
            return createBookmarksSectionLayout(for: traitCollection)
        }
    }

    private func createSingleItemSectionLayout(
        for traitCollection: UITraitCollection,
        itemHeight: CGFloat = UX.standardSingleItemHeight,
        topInsets: CGFloat = 0,
        bottomInsets: CGFloat = 0
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(itemHeight))

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(itemHeight))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: topInsets,
            leading: leadingInset,
            bottom: bottomInsets,
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

    private func createTopSitesSectionLayout(
        for traitCollection: UITraitCollection,
        numberOfTilesPerRow: Int
    ) -> NSCollectionLayoutSection {
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

    private func createJumpBackInSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        // TODO: FXIOS-11224 Update section layout for jump back in
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.itemHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.JumpBackInConstants.itemHeight)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 1)

        let section = NSCollectionLayoutSection(group: group)
        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: leadingInset,
                    bottom: UX.spacingBetweenSections,
                    trailing: leadingInset)

        return section
    }

    private func createBookmarksSectionLayout(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.BookmarksConstants.cellWidth),
            heightDimension: .estimated(UX.BookmarksConstants.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(UX.BookmarksConstants.cellWidth),
            heightDimension: .estimated(UX.BookmarksConstants.cellHeight)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: leadingInset,
            bottom: UX.spacingBetweenSections,
            trailing: 0)

        section.interGroupSpacing = UX.interGroupSpacing
        section.orthogonalScrollingBehavior = .continuous

        return section
    }
}
