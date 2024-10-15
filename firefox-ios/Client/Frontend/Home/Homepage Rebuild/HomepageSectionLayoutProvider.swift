// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Holds section layout logic for the new homepage as part of the rebuild project
final class HomepageSectionLayoutProvider {
    struct UX {
        static let standardInset: CGFloat = 16
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
            static let interGroupSpacing: CGFloat = 8

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
            return self.createLayoutSection(for: section, with: environment.traitCollection)
        }
    }

    // TODO: FXIOS-10162 - Update layout section with appropriate views + integrate with redux
    private func createLayoutSection(
        for section: HomepageSection,
        with traitCollection: UITraitCollection
    ) -> NSCollectionLayoutSection {
        switch section {
        case .header:
            return createHeaderSectionLayout(for: traitCollection)
        case .topSites:
            return createDefaultSectionLayout()
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
            trailing: UX.PocketConstants.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: leadingInset,
                                                        bottom: UX.standardInset,
                                                        trailing: 0)
        section.orthogonalScrollingBehavior = .continuous
        return section
    }

    // TODO: FXIOS-10161 - Update with proper section layout
    private func createDefaultSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

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
