// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TabsSectionManager {
    struct UX {
        static let cellEstimatedHeight: CGFloat = 200
        static let cardSpacing: CGFloat = 16
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25
        static let verticalInset: CGFloat = 20
    }

    static func leadingInset(traitCollection: UITraitCollection,
                             interfaceIdiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> CGFloat {
        guard interfaceIdiom != .phone else { return UX.standardInset }

        // Handles multitasking on iPad
        return traitCollection.horizontalSizeClass == .regular ? UX.iPadInset : UX.standardInset
    }

    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .estimated(UX.cellEstimatedHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellEstimatedHeight)
        )

        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 2)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.cardSpacing)
        let section = NSCollectionLayoutSection(group: group)

        let horizontalInset = TabsSectionManager.leadingInset(traitCollection: layoutEnvironment.traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: UX.verticalInset,
                                                        leading: horizontalInset,
                                                        bottom: UX.verticalInset,
                                                        trailing: horizontalInset)
        section.interGroupSpacing = UX.cardSpacing

        return section
    }
}
