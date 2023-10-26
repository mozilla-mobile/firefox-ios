// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class TabsSectionManager {
    struct UX {
        static let cellEstimatedHeight: CGFloat = 400
        static let cardSpacing: CGFloat = 16
        static let standardInset: CGFloat = 18
        static let iPadInset: CGFloat = 50
        static let iPadTopSiteInset: CGFloat = 25
    }

//    private var trailingSwipeClosure: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? = { indexPath in
//        let deleteAction = UIContextualAction(
//            style: .destructive,
//            title: .TabsTray.InactiveTabs.CloseInactiveTabSwipeActionTitle) { _, _, completion in
//            // TODO: FXIOS-6936 Handle action
//            completion(true)
//        }
//        deleteAction.backgroundColor = .systemGreen
//        return UISwipeActionsConfiguration(actions: [deleteAction])
//    }

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

//        let interface = TopSitesUIInterface(trait: traitCollection, availableWidth: size.width)
//        let sectionDimension = dimensionManager.getSectionDimension(for: topSites,
//                                                                    numberOfRows: topSitesDataAdaptor.numberOfRows,
//                                                                    interface: interface)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitem: item,
                                                       count: 2)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(UX.cardSpacing)
        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = TabsSectionManager.leadingInset(traitCollection: layoutEnvironment.traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 20,
                                                        leading: leadingInset,
                                                        bottom: 20,
                                                        trailing: leadingInset)
        section.interGroupSpacing = UX.cardSpacing

        return section
    }
}
