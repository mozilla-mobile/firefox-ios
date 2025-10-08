// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct StoriesFeedSectionLayoutProvider {
    struct UX {
        static let cellSize = CGSize(width: 361, height: 282)
        static let interItemSpacing: CGFloat = 16
        static let interGroupSpacing: CGFloat = 16
        static let fractionalGroupWidth: CGFloat = 0.92
        static let topSectionInset: CGFloat = 10
    }

    @MainActor
    static func createStoriesFeedSectionLayout(
        for environment: NSCollectionLayoutEnvironment
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellSize.height)
        )

        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(UX.cellSize.height)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            subitem: item,
            count: 1
        )
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.interItemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        let containerWidth = environment.container.effectiveContentSize.width
        let horizontalInsets = (containerWidth - UX.cellSize.width) / 2
        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topSectionInset,
            leading: horizontalInsets,
            bottom: 0,
            trailing: horizontalInsets
        )
        section.interGroupSpacing = UX.interGroupSpacing

        return section
    }
}
