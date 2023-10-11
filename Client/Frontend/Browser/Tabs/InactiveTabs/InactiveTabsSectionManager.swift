// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class InactiveTabsSectionManager {
    struct UX {
        static let margin: CGFloat = 15.0
        static let headerEstimatedHeight: CGFloat = 48
        static let footerEstimatedHeight: CGFloat = 88
    }

    var items = ["One",
                 "Two",
                 "Three",
                 "Four",
                 "Five",
                 "Six"]
    var collectionViewWidth: Double

    init( collectionViewWidth: Double) {
        self.collectionViewWidth = collectionViewWidth
    }

    func layoutSection(
        _ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var sectionConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        sectionConfig.headerMode = .firstItemInSection
        let section = NSCollectionLayoutSection.list(using: sectionConfig,
                                                     layoutEnvironment: layoutEnvironment)

        // Supplementary Items: Header and Footer
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .estimated(UX.headerEstimatedHeight))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)

        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                heightDimension: .estimated(UX.footerEstimatedHeight))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
        section.boundarySupplementaryItems = [header, footer]

        return section
    }
}
