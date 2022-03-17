// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomePanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowActions]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: site, with: indexPath) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site, homePanelDelegate: HomePanelDelegate?, isPocket: Bool, isZeroSearch: Bool) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            if isPocket {
                let originExtras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .pocketStory,
                                             extras: originExtras)
            }
        }.items

        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            homePanelDelegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }.items

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}
