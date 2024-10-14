// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Holds section layout logic for the new homepage as part of the rebuild project
final class HomepageSectionLayoutProvider {
    struct UX {
        static let bottomSpacing: CGFloat = 30
        static let standardInset: CGFloat = 16
        static let iPadInset: CGFloat = 50

        static func leadingInset(
            traitCollection: UITraitCollection,
            interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        ) -> CGFloat {
            guard interfaceIdiom != .phone else { return standardInset }

            // Handles multitasking on iPad
            return traitCollection.horizontalSizeClass == .regular ? iPadInset : standardInset
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
            return createFirstSectionLayout()
        case .pocket:
            return createDefaultSectionLayout()
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
            bottom: UX.bottomSpacing,
            trailing: leadingInset)

        return section
    }

    // TODO: FXIOS-10165 - Update with proper top sites section layout
    private func createFirstSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)

        group.interItemSpacing = .fixed(10)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

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
}
