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

    private var trailingSwipeClosure: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? = { indexPath in
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: .TabsTray.InactiveTabs.CloseInactiveTabSwipeActionTitle) { _, _, completion in
            // TODO: FXIOS-6936 Handle action
            completion(true)
        }
        deleteAction.backgroundColor = .systemGreen
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func layoutSection(_ layoutEnvironment: NSCollectionLayoutEnvironment,
                       isExpanded: Bool) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .grouped)
        config.headerMode = .firstItemInSection
        config.footerMode = .supplementary
        config.showsSeparators = false
        config.trailingSwipeActionsConfigurationProvider = trailingSwipeClosure
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)

        // Supplementary Item
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

        section.boundarySupplementaryItems = isExpanded ? [header, footer] : [header]
        return section
    }
}
