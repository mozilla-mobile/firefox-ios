/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import Shared

protocol LibraryPanelContextMenu {
    func getSiteDetails(for indexPath: IndexPath) -> Site?
    func getContextMenuActions(for site: Site, with indexPath: IndexPath) -> [PhotonRowItems]?
    func presentContextMenu(for indexPath: IndexPath)
    func presentContextMenu(for site: Site, with indexPath: IndexPath, completionHandler: @escaping () -> PhotonActionSheet?)
}

extension LibraryPanelContextMenu {
    func presentContextMenu(for indexPath: IndexPath) {
        guard let site = getSiteDetails(for: indexPath) else { return }

        presentContextMenu(for: site, with: indexPath, completionHandler: {
            return self.contextMenu(for: site, with: indexPath)
        })
    }

    func contextMenu(for site: Site, with indexPath: IndexPath) -> PhotonActionSheet? {
        guard let actions = self.getContextMenuActions(for: site, with: indexPath) else { return nil }

        let viewModel = PhotonActionSheetViewModel(actions: [actions], site: site, modalStyle: .overFullScreen)
        let contextMenu = PhotonActionSheet(viewModel: viewModel)
        contextMenu.modalTransitionStyle = .crossDissolve

        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        return contextMenu
    }
    
    func getRecentlyClosedTabContexMenuActions(for site: Site, recentlyClosedPanelDelegate: RecentlyClosedPanelDelegate?) ->  [PhotonRowItems]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleSheetItem(title: .OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            recentlyClosedPanelDelegate?.openRecentlyClosedSiteInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = SingleSheetItem(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            recentlyClosedPanelDelegate?.openRecentlyClosedSiteInNewTab(siteURL, isPrivate: true)
        }

        return [PhotonRowItems(openInNewTabAction), PhotonRowItems(openInNewPrivateTabAction)]
    }
    
    func getRemoteTabContexMenuActions(for site: Site, remotePanelDelegate: RemotePanelDelegate?) ->  [PhotonRowItems]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleSheetItem(title: .OpenInNewTabContextMenuTitle, iconString: "quick_action_new_tab") { _, _ in
            remotePanelDelegate?.remotePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }

        let openInNewPrivateTabAction = SingleSheetItem(title: .OpenInNewPrivateTabContextMenuTitle, iconString: "quick_action_new_private_tab") { _, _ in
            remotePanelDelegate?.remotePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }

        return [PhotonRowItems(openInNewTabAction), PhotonRowItems(openInNewPrivateTabAction)]
    }

    func getDefaultContextMenuActions(for site: Site, libraryPanelDelegate: LibraryPanelDelegate?) -> [PhotonRowItems]? {
        guard let siteURL = URL(string: site.url) else { return nil }

        let openInNewTabAction = SingleSheetItem(title: .OpenInNewTabContextMenuTitle,
                                                 iconString: "quick_action_new_tab") { _, _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)
        }.items
        
        let openInNewPrivateTabAction = SingleSheetItem(title: .OpenInNewPrivateTabContextMenuTitle,
                                                        iconString: "quick_action_new_private_tab") { _, _ in
            libraryPanelDelegate?.libraryPanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
        }.items
        
        return [openInNewTabAction, openInNewPrivateTabAction]
    }
}
