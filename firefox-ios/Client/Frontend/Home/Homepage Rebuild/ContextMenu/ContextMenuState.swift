// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Storage

/// State to populate actions for the `PhotonActionSheet` view
/// Ideally, we want that view to subscribe to the store and update its state following the redux pattern
/// For now, we will instantiate this state and populate the associated view model instead to avoid
/// increasing scope of homepage rebuild project.

struct ContextMenuState {
    var site: Site?
    var actions: [[PhotonRowActions]] = [[]]

    init(configuration: ContextMenuConfiguration) {
        guard let site = configuration.site else { return }
        self.site = site

        switch configuration.homepageSection {
        case .topSites:
            actions = [getTopSitesActions(site: site)]
        case .pocket:
            actions = [getPocketActions(site: site)]
        default:
            return
        }
    }

    // MARK: - Top sites item's context menu actions
    private func getTopSitesActions(site: Site) -> [PhotonRowActions] {
        let topSiteActions: [PhotonRowActions]
        if site is PinnedSite {
            topSiteActions = getPinnedTileActions()
        } else if site as? SponsoredTile != nil {
            topSiteActions = getSponsoredTileActions()
        } else {
            topSiteActions = getOtherTopSitesActions()
        }
        return topSiteActions
    }

    private func getPinnedTileActions() -> [PhotonRowActions] {
        return [getRemovePinTopSiteAction(),
                getOpenInNewTabAction(),
                getOpenInNewPrivateTabAction(),
                getRemoveTopSiteAction(),
                getShareAction()]
    }

    private func getSponsoredTileActions() -> [PhotonRowActions] {
        return [getOpenInNewTabAction(),
                getOpenInNewPrivateTabAction(),
                getSettingsAction(),
                getSponsoredContentAction(),
                getShareAction()]
    }

    private func getOtherTopSitesActions() -> [PhotonRowActions] {
        return [getPinTopSiteAction(),
                getOpenInNewTabAction(),
                getOpenInNewPrivateTabAction(),
                getRemoveTopSiteAction(),
                getShareAction()]
    }

    /// This action removes the tile out of the top sites.
    /// If site is pinned, it removes it from pinned and remove from top sites in general.
    private func getRemoveTopSiteAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .RemoveContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.cross,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }

    private func getPinTopSiteAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .PinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pin,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }

    /// This unpin action removes the top site from the location it's in.
    /// The tile can stil appear in the top sites as unpinned.
    private func getRemovePinTopSiteAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .UnpinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pinSlash,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }

    private func getSettingsAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.Settings,
                                     iconString: StandardImageIdentifiers.Large.settings,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }

    private func getSponsoredContentAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
                                     iconString: StandardImageIdentifiers.Large.helpCircle,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }

    // MARK: - Pocket item's context menu actions
    private func getPocketActions(site: Site) -> [PhotonRowActions] {
        let openInNewTabAction = getOpenInNewTabAction()
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction()
        let shareAction = getShareAction()
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: - Default actions
    private func getOpenInNewTabAction() -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.plus,
            allowIconScaling: true
        ) { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }.items
    }

    private func getOpenInNewPrivateTabAction() -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewPrivateTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.privateMode,
            allowIconScaling: true
        ) { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }.items
    }

    private func getBookmarkAction(site: Site) -> PhotonRowActions {
        let bookmarkAction: SingleActionViewModel
        if site.bookmarked ?? false {
            bookmarkAction = getRemoveBookmarkAction()
        } else {
            bookmarkAction = getAddBookmarkAction()
        }
        return bookmarkAction.items
    }

    private func getRemoveBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmarkSlash,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        })
    }

    private func getAddBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmark,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        })
    }

    private func getShareAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .ShareContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.share,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // TODO: FXIOS-10613 - Add proper actions
        }).items
    }
}
