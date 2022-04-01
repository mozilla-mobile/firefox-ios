// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation
import Storage

protocol HomePanelContextMenu {
    func getContextMenuActions(for site: Site, with sourceView: UIView?) -> [PhotonRowActions]?
    func presentContextMenu(with site: Site, with sourceView: UIView?)
    func presentContextMenu(for site: Site, with sourceView: UIView?, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension HomePanelContextMenu {
    func presentContextMenu(with site: Site, with sourceView: UIView?) {
        presentContextMenu(for: site, with: sourceView, completionHandler: {
            return self.contextMenu(for: site, with: sourceView)
        })
    }

    func contextMenu(for site: Site, with sourceView: UIView?) -> PhotonActionSheet? {
        guard let actions = getContextMenuActions(for: site, with: sourceView) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }

    func getDefaultContextMenuActions(for site: Site,
                                      delegate: FirefoxHomeContextMenuHelperDelegate?,
//                                      isPocket: Bool,
                                      isZeroSearch: Bool) -> [PhotonRowActions]? {

        guard let siteURL = site.url.asURL else { return nil }

        let openInNewTabAction = SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: ImageIdentifiers.newTab) { _ in
            delegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
            // TODO: Laurie - Put this in viewModel of pocket
//            if isPocket {
//                let originExtras = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
//                TelemetryWrapper.recordEvent(category: .action,
//                                             method: .tap,
//                                             object: .pocketStory,
//                                             extras: originExtras)
//            }
        }.items

        let openInNewPrivateTabAction = SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _ in
            delegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }.items

        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}
