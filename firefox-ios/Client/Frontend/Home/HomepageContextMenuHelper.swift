// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

import enum MozillaAppServices.BookmarkRoots

// swiftlint:disable class_delegate_protocol
protocol HomepageContextMenuHelperDelegate: UIViewController {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    func homePanelDidRequestToOpenSettings(at settingsPage: Route.SettingsSection)
    func homePanelDidRequestBookmarkToast(urlString: String?, action: BookmarkAction)
}
// swiftlint:enable class_delegate_protocol

extension HomepageContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }
}

enum BookmarkAction {
    case add
    case remove
}

class HomepageContextMenuHelper: HomepageContextMenuProtocol,
                                 BookmarksRefactorFeatureFlagProvider,
                                 CanRemoveQuickActionBookmark {
    typealias ContextHelperDelegate = HomepageContextMenuHelperDelegate & UIPopoverPresentationControllerDelegate
    private let profile: Profile
    private var viewModel: HomepageViewModel
    private let toastContainer: UIView
    private let bookmarksSaver: BookmarksSaver
    let bookmarksHandler: BookmarksHandler
    weak var browserNavigationHandler: BrowserNavigationHandler?
    weak var delegate: ContextHelperDelegate?
    var getPopoverSourceRect: ((UIView?) -> CGRect)?
    private let bookmarksTelemetry = BookmarksTelemetry()

    init(
        profile: Profile,
        viewModel: HomepageViewModel,
        toastContainer: UIView,
        bookmarksSaver: BookmarksSaver? = nil
    ) {
        self.profile = profile
        self.viewModel = viewModel
        self.toastContainer = toastContainer
        self.bookmarksSaver = bookmarksSaver ?? DefaultBookmarksSaver(profile: viewModel.profile)
        self.bookmarksHandler = profile.places
    }

    func presentContextMenu(for site: Site,
                            with sourceView: UIView?,
                            sectionType: HomepageSectionType,
                            completionHandler: @escaping (Site) -> PhotonActionSheet?
    ) {
        fetchBookmarkStatus(for: site) { site in
            guard let contextMenu = completionHandler(site) else { return }
            self.delegate?.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getContextMenuActions(
        for site: Site,
        with sourceView: UIView?,
        sectionType: HomepageSectionType
    ) -> [PhotonRowActions]? {
        var actions = [PhotonRowActions]()
        if sectionType == .topSites,
           let topSitesActions = getTopSitesActions(site: site, with: sourceView) {
            actions = topSitesActions
        } else if sectionType == .pocket,
                  let pocketActions = getPocketActions(site: site, with: sourceView) {
            actions = pocketActions
        } else if sectionType == .bookmarks,
                  let bookmarksActions = getBookmarksActions(site: site, with: sourceView) {
            actions = bookmarksActions
        } else if sectionType == .jumpBackIn,
                  let jumpBackInActions = getJumpBackInActions(site: site, with: sourceView) {
            actions = jumpBackInActions
        }

        return actions
    }

    // MARK: - Default actions
    func getOpenInNewPrivateTabAction(siteURL: URL, sectionType: HomepageSectionType) -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewPrivateTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.privateMode,
            allowIconScaling: true
        ) { _ in
            self.delegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
            sectionType.newPrivateTabActionTelemetry()
        }.items
    }

    // MARK: Jump Back In

    private func getJumpBackInActions(site: Site, with sourceView: UIView?) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL, sectionType: .jumpBackIn)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .jumpBackIn)
        let shareAction = getShareAction(site: site, sourceView: sourceView)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: Bookmarks

    private func getBookmarksActions(site: Site, with sourceView: UIView?) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL, sectionType: .bookmarks)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .bookmarks)
        let shareAction = getShareAction(site: site, sourceView: sourceView)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    // MARK: - Pocket
    private func getPocketActions(site: Site, with sourceView: UIView?) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let openInNewTabAction = getOpenInNewTabAction(siteURL: siteURL, sectionType: .pocket)
        let openInNewPrivateTabAction = getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .pocket)
        let shareAction = getShareAction(site: site, sourceView: sourceView)
        let bookmarkAction = getBookmarkAction(site: site)

        return [openInNewTabAction, openInNewPrivateTabAction, bookmarkAction, shareAction]
    }

    private func getOpenInNewTabAction(siteURL: URL, sectionType: HomepageSectionType) -> PhotonRowActions {
        return SingleActionViewModel(
            title: .OpenInNewTabContextMenuTitle,
            iconString: StandardImageIdentifiers.Large.plus,
            allowIconScaling: true
        ) { _ in
            self.delegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: false)

            if sectionType == .pocket {
                let originExtras = TelemetryWrapper.getOriginExtras(isZeroSearch: self.viewModel.isZeroSearch)
                TelemetryWrapper.recordEvent(category: .action,
                                             method: .tap,
                                             object: .pocketStory,
                                             extras: originExtras)
            }
        }.items
    }

    private func getBookmarkAction(site: Site) -> PhotonRowActions {
        let bookmarkAction: SingleActionViewModel
        if site.isBookmarked ?? false {
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
            self.viewModel.profile.places.deleteBookmarksWithURL(url: site.url).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.removeBookmarkShortcut()
            }

            self.delegate?.homePanelDidRequestBookmarkToast(urlString: site.url, action: .remove)
            self.bookmarksTelemetry.deleteBookmark(eventLabel: .activityStream)
        })
    }

    private func getAddBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmark,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            let shareItem = ShareItem(url: site.url, title: site.title)

            Task {
                await self.bookmarksSaver.createBookmark(url: shareItem.url, title: shareItem.title, position: 0)
            }

            var userData = [QuickActionInfos.tabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActionInfos.tabTitleKey] = title
            }
            QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                 withUserData: userData,
                                                                                 toApplication: .shared)

            self.delegate?.homePanelDidRequestBookmarkToast(urlString: shareItem.url, action: .add)
            self.bookmarksTelemetry.addBookmark(eventLabel: .activityStream)
        })
    }

    /// Handles share from long press on pocket articles, jump back in websites, bookmarks, etc. on the home screen.
    /// - Parameters:
    ///   - site: Site for pocket article
    ///   - sourceView: View to show the popover
    /// - Returns: Share action
    private func getShareAction(site: Site, sourceView: UIView?) -> PhotonRowActions {
        return SingleActionViewModel(title: .ShareContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.share,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            guard let url = URL(string: site.url) else { return }

            self.browserNavigationHandler?.showShareSheet(
                shareType: .site(url: url),
                shareMessage: nil,
                sourceView: sourceView ?? UIView(),
                sourceRect: nil,
                toastContainer: self.toastContainer,
                popoverArrowDirection: [.up, .down, .left])
        }).items
    }

    // MARK: - Top sites

    func getTopSitesActions(site: Site, with sourceView: UIView?) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let topSiteActions: [PhotonRowActions]

        switch site.type {
        case .sponsoredSite:
            topSiteActions = [getOpenInNewTabAction(siteURL: siteURL, sectionType: .topSites),
                              getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getSettingsAction(),
                              getSponsoredContentAction(),
                              getShareAction(site: site, sourceView: sourceView)]

        case .pinnedSite:
            topSiteActions = [getRemovePinTopSiteAction(site: site),
                              getOpenInNewTabAction(siteURL: siteURL, sectionType: .topSites),
                              getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getRemoveTopSiteAction(site: site),
                              getShareAction(site: site, sourceView: sourceView)]
        default:
            topSiteActions = [getPinTopSiteAction(site: site),
                              getOpenInNewTabAction(siteURL: siteURL, sectionType: .topSites),
                              getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getRemoveTopSiteAction(site: site),
                              getShareAction(site: site, sourceView: sourceView)]
        }

        return topSiteActions
    }

    // Removes the site out of the top sites. If site is pinned it removes it from pinned and remove
    private func getRemoveTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .RemoveContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.cross,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            self.viewModel.topSiteViewModel.removePinTopSite(site)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.viewModel.topSiteViewModel.hideURLFromTopSites(site)
            }

            self.sendTopSiteContextualTelemetry(type: .remove)
        }).items
    }

    private func getPinTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .PinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pin,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            self.viewModel.topSiteViewModel.pinTopSite(site)
            self.sendTopSiteContextualTelemetry(type: .pin)
        }).items
    }

    // Unpin removes it from the location it's in. Still can appear in the top sites as unpin
    private func getRemovePinTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .UnpinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pinSlash,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            self.viewModel.topSiteViewModel.removePinTopSite(site)
            self.sendTopSiteContextualTelemetry(type: .unpin)
        }).items
    }

    private func getSettingsAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.Settings,
                                     iconString: StandardImageIdentifiers.Large.settings,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            self.delegate?.homePanelDidRequestToOpenSettings(at: .topSites)
            self.sendTopSiteContextualTelemetry(type: .settings)
        }).items
    }

    private func getSponsoredContentAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
                                     iconString: StandardImageIdentifiers.Large.helpCircle,
                                     allowIconScaling: true,
                                     tapHandler: { _ in
            guard let url = SupportUtils.URLForTopic("sponsor-privacy") else { return }
            self.delegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: false, selectNewTab: true)
            self.sendTopSiteContextualTelemetry(type: .sponsoredSupport)
        }).items
    }

    private func fetchBookmarkStatus(for site: Site, completionHandler: @escaping (Site) -> Void) {
        viewModel.profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            var updatedSite = site
            updatedSite.isBookmarked = result.successValue ?? false
            completionHandler(updatedSite)
        }
    }

    // MARK: Telemetry

    enum ContextualActionType: String {
        case remove, unpin, pin, settings, sponsoredSupport
    }

    private func sendTopSiteContextualTelemetry(type: ContextualActionType) {
        let extras = [TelemetryWrapper.EventExtraKey.contextualMenuType.rawValue: type.rawValue]
        TelemetryWrapper.recordEvent(
            category: .action,
            method: .view,
            object: .topSiteContextualMenu,
            value: nil,
            extras: extras
        )
    }
}
