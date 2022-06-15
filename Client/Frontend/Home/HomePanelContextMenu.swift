// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomePanelContextMenu {
    func getContextMenuActions(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> [PhotonRowActions]?
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType)
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType, completionHandler: @escaping () -> PhotonActionSheet?)

    func getContextMenuActions(for highlightItem: HighlightItem, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> [PhotonRowActions]?
    func presentContextMenu(for highlightItem: HighlightItem, with sourceView: UIView?, sectionType: FirefoxHomeSectionType)
    func presentContextMenu(for highlightItem: HighlightItem, with sourceView: UIView?, sectionType: FirefoxHomeSectionType, completionHandler: @escaping () -> PhotonActionSheet?)

}

extension HomePanelContextMenu {
    // MARK: Site
    func presentContextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) {
        presentContextMenu(for: site, with: sourceView, sectionType: sectionType, completionHandler: {
            return self.contextMenu(for: site, with: sourceView, sectionType: sectionType)
        })
    }

    func contextMenu(for site: Site, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> PhotonActionSheet? {
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
    func presentContextMenu(for highlightItem: HighlightItem, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) {
        presentContextMenu(for: highlightItem, with: sourceView, sectionType: sectionType, completionHandler: {
            return self.contextMenu(for: highlightItem, with: sourceView, sectionType: sectionType)
        })
    }
    func contextMenu(for highlightItem: HighlightItem, with sourceView: UIView?, sectionType: FirefoxHomeSectionType) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: highlightItem,
                                                  with: sourceView,
                                                  sectionType: sectionType)
        else { return nil }

        var viewModel: PhotonActionSheetViewModel

        switch highlightItem.type {
        case .item:
            guard let url = highlightItem.siteUrl?.absoluteString else { return nil }
            let site = Site(url: url, title: highlightItem.displayTitle)

            viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   site: site,
                                                   modalStyle: .overFullScreen)
        case .group:
            viewModel = PhotonActionSheetViewModel(actions: [actions],
                                                   title: highlightItem.displayTitle,
                                                   modalStyle: .overFullScreen)
        }

        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
}
