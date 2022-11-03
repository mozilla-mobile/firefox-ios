// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomepageContextMenuProtocol {
    func getContextMenuActions(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType) -> [PhotonRowActions]?
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType)
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType, completionHandler: @escaping () -> PhotonActionSheet?)

    func getContextMenuActions(for recentlyVisitedItem: RecentlyVisitedItem, with sourceView: UIView?, sectionType: HomepageSectionType) -> [PhotonRowActions]?
    func presentContextMenu(for recentlyVisitedItem: RecentlyVisitedItem, with sourceView: UIView?, sectionType: HomepageSectionType)
    func presentContextMenu(for recentlyVisitedItem: RecentlyVisitedItem, with sourceView: UIView?, sectionType: HomepageSectionType, completionHandler: @escaping () -> PhotonActionSheet?)

}

extension HomepageContextMenuProtocol {
    // MARK: Site
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType) {
        presentContextMenu(for: site, with: sourceView, sectionType: sectionType, completionHandler: {
            return self.contextMenu(for: site, with: sourceView, sectionType: sectionType)
        })
    }

    func contextMenu(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: site,
                                                  with: sourceView,
                                                  sectionType: sectionType)
        else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   site: site,
                                                   modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    // MARK: - Highlight Item
    func presentContextMenu(for recentlyVisitedItem: RecentlyVisitedItem, with sourceView: UIView?, sectionType: HomepageSectionType) {
        presentContextMenu(for: recentlyVisitedItem, with: sourceView, sectionType: sectionType, completionHandler: {
            return self.contextMenu(for: recentlyVisitedItem, with: sourceView, sectionType: sectionType)
        })
    }
    func contextMenu(for recentlyVisitedItem: RecentlyVisitedItem, with sourceView: UIView?, sectionType: HomepageSectionType) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: recentlyVisitedItem,
                                                  with: sourceView,
                                                  sectionType: sectionType)
        else { return nil }

        var viewModel: PhotonActionSheetViewModel

        switch recentlyVisitedItem.type {
        case .item:
            guard let url = recentlyVisitedItem.siteUrl?.absoluteString else { return nil }
            let site = Site(url: url, title: recentlyVisitedItem.displayTitle)

            viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   site: site,
                                                   modalStyle: .overFullScreen)
        case .group:
            viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   title: recentlyVisitedItem.displayTitle,
                                                   modalStyle: .overFullScreen)
        }

        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
}
