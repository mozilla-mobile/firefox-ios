// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage
import Redux

/// A protocol that defines methods for handling bookmark operations.
/// Classes conforming to this protocol can manage adding and removing bookmarks.
/// Since bookmarks are not using Redux, we use this instead of dispatching an action.
protocol BookmarksHandlerDelegate: AnyObject {
    func addBookmark(url: String, title: String?, site: Site?)
    func removeBookmark(url: URL, title: String?, site: Site?)
}

/// State to populate actions for the `PhotonActionSheet` view
/// Ideally, we want that view to subscribe to the store and update its state following the redux pattern
/// For now, we will instantiate this state and populate the associated view model instead to avoid
/// increasing scope of homepage rebuild project.

struct ContextMenuState {
    var site: Site?
    var actions: [[PhotonRowActions]] = [[]]

    private let profile: Profile
    private let bookmarkDelegate: BookmarksHandlerDelegate
    private let configuration: ContextMenuConfiguration
    private let windowUUID: WindowUUID
    private let logger: Logger

    weak var coordinatorDelegate: ContextMenuCoordinator?

    init(
        profile: Profile = AppContainer.shared.resolve(),
        bookmarkDelegate: BookmarksHandlerDelegate,
        configuration: ContextMenuConfiguration,
        windowUUID: WindowUUID,
        logger: Logger = DefaultLogger.shared
    ) {
        self.profile = profile
        self.bookmarkDelegate = bookmarkDelegate
        self.configuration = configuration
        self.windowUUID = windowUUID
        self.logger = logger

        guard let site = configuration.site else { return }
        self.site = site

        switch configuration.homepageSection {
        case .topSites:
            actions = [getTopSitesActions(site: site)]
        case .jumpBackIn:
            actions = [getJumpBackInActions(site: site)]
        case .bookmarks:
            actions = [getBookmarksActions(site: site)]
        case .pocket:
            actions = [getPocketActions(site: site)]
        default:
            return
        }
    }

    // MARK: - Top sites item's context menu actions
    private func getTopSitesActions(site: Site) -> [PhotonRowActions] {
        let topSiteActions: [PhotonRowActions]

        switch site.type {
        case .sponsoredSite:
            topSiteActions = getSponsoredTileActions(site: site)
        case .pinnedSite:
            topSiteActions = getPinnedTileActions(site: site)
        default:
            topSiteActions = getOtherTopSitesActions(site: site)
        }

        return topSiteActions
    }

    private func getPinnedTileActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }
        return [getRemovePinTopSiteAction(site: site),
                getOpenInNewTabAction(siteURL: siteURL),
                getOpenInNewPrivateTabAction(siteURL: siteURL),
                getRemoveTopSiteAction(site: site),
                getShareAction(siteURL: site.url)]
    }

    private func getSponsoredTileActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }
        return [getOpenInNewTabAction(siteURL: siteURL),
                getOpenInNewPrivateTabAction(siteURL: siteURL),
                getSettingsAction(),
                getSponsoredContentAction(),
                getShareAction(siteURL: site.url)]
    }

    private func getOtherTopSitesActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }
        return [getPinTopSiteAction(site: site),
                getOpenInNewTabAction(siteURL: siteURL),
                getOpenInNewPrivateTabAction(siteURL: siteURL),
                getRemoveTopSiteAction(site: site),
                getShareAction(siteURL: site.url)]
    }

    /// This action removes the tile out of the top sites.
    /// If site is pinned, it removes it from pinned and remove from top sites in general.
    private func getRemoveTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .RemoveContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.cross,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            dispatchContextMenuAction(site: site, actionType: ContextMenuActionType.tappedOnRemoveTopSite)
            // TODO: FXIOS-10171 - Add telemetry
        }).items
    }

    private func getPinTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .PinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pin,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            dispatchContextMenuAction(site: site, actionType: ContextMenuActionType.tappedOnPinTopSite)
            // TODO: FXIOS-10171 - Add telemetry
        }).items
    }

    /// This unpin action removes the top site from the location it's in.
    /// The tile can stil appear in the top sites as unpinned.
    private func getRemovePinTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .UnpinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pinSlash,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            dispatchContextMenuAction(site: site, actionType: ContextMenuActionType.tappedOnUnpinTopSite)
            // TODO: FXIOS-10171 - Add telemetry
        }).items
    }

    private func getSettingsAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.Settings,
                                     iconString: StandardImageIdentifiers.Large.settings,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            dispatchSettingsAction(section: .topSites)
            // TODO: FXIOS-10171 - Add telemetry
        }).items
    }

    private func getSponsoredContentAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
                                     iconString: StandardImageIdentifiers.Large.helpCircle,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            guard let url = SupportUtils.URLForTopic("sponsor-privacy") else {
                self.logger.log(
                    "Unable to retrieve URL for sponsor-privacy, return early",
                    level: .warning,
                    category: .homepage
                )
                return
            }
            dispatchOpenNewTabAction(siteURL: url, isPrivate: false, selectNewTab: true)
            // TODO: FXIOS-10171 - Add telemetry
        }).items
    }

    // MARK: - JumpBack In section item's context menu actions
    private func getJumpBackInActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }

        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL)
        let shareAction = getShareAction(siteURL: site.url)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: - Homepage Bookmarks section item's context menu actions
    private func getBookmarksActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }

        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL)
        let shareAction = getShareAction(siteURL: site.url)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: - Pocket item's context menu actions
    private func getPocketActions(site: Site) -> [PhotonRowActions] {
        guard let siteURL = site.url.asURL else { return [] }
        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL)
        let shareAction = getShareAction(siteURL: site.url)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: - Default actions
    private func getOpenInNewTabAction(siteURL: URL) -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.plus,
            allowIconScaling: true
        ) { _ in
            dispatchOpenNewTabAction(siteURL: siteURL, isPrivate: false)
            // TODO: FXIOS-10171 - Add telemetry
        }.items
    }

    private func getOpenInNewPrivateTabAction(siteURL: URL) -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewPrivateTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.privateMode,
            allowIconScaling: true
        ) { _ in
            dispatchOpenNewTabAction(siteURL: siteURL, isPrivate: true)
            // TODO: FXIOS-10171 - Add telemetry
        }.items
    }

    private func getBookmarkAction(site: Site) -> PhotonRowActions {
        let bookmarkAction: SingleActionViewModel
        let isBookmarked = profile.places.isBookmarked(url: site.url).value.successValue ?? false
        if isBookmarked {
            bookmarkAction = getRemoveBookmarkAction(site: site)
        } else {
            bookmarkAction = getAddBookmarkAction(site: site)
        }
        return bookmarkAction.items
    }

    private func getRemoveBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmarkSlash,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            guard let siteURL = site.url.asURL else {
                self.logger.log(
                    "Unable to retrieve URL for \(site.url), unable to remove bookmarks",
                    level: .warning,
                    category: .homepage
                )
                return
            }
            bookmarkDelegate.removeBookmark(url: siteURL, title: site.title, site: site)
            // TODO: FXIOS-10171 - Add telemetry
        })
    }

    private func getAddBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmark,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            // The method in BVC also handles the toast for this use case
            bookmarkDelegate.addBookmark(url: site.url, title: site.title, site: site)
            // TODO: FXIOS-10171 - Add telemetry
        })
    }

    private func getShareAction(siteURL: String) -> PhotonRowActions {
        return SingleActionViewModel(
            title: .ShareContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.share,
            allowIconScaling: true,
            tapHandler: { _ in
                guard let url = URL(string: siteURL, invalidCharacters: false) else {
                    self.logger.log(
                        "Unable to retrieve URL for \(siteURL), return early",
                        level: .warning,
                        category: .homepage
                    )
                    return
                }
                let shareSheetConfiguration = ShareSheetConfiguration(
                    shareType: .site(url: url),
                    shareMessage: nil,
                    sourceView: configuration.sourceView ?? UIView(),
                    sourceRect: nil,
                    toastContainer: configuration.toastContainer,
                    popoverArrowDirection: [.up, .down, .left]
                )

                dispatchShareSheetAction(shareSheetConfiguration: shareSheetConfiguration)
            }).items
    }

    // MARK: Dispatch Actions
    private func dispatchSettingsAction(section: Route.SettingsSection) {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.settings(section)),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnSettingsSection
            )
        )
    }

    private func dispatchOpenNewTabAction(siteURL: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(
                    .newTab,
                    url: siteURL,
                    isPrivate: isPrivate,
                    selectNewTab: selectNewTab
                ),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnOpenInNewTab
            )
        )
    }

    private func dispatchShareSheetAction(shareSheetConfiguration: ShareSheetConfiguration) {
        store.dispatch(
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.shareSheet(shareSheetConfiguration)),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnShareSheet
            )
        )
    }

    private func dispatchContextMenuAction(site: Site, actionType: ActionType) {
        store.dispatch(
            ContextMenuAction(
                site: site,
                windowUUID: windowUUID,
                actionType: actionType
            )
        )
    }
}
