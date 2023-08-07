// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage

// swiftlint:disable class_delegate_protocol
protocol HomepageContextMenuHelperDelegate: UIViewController {
    func presentWithModalDismissIfNeeded(_ viewController: UIViewController, animated: Bool)
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool)
    func homePanelDidRequestToOpenSettings(at settingsPage: AppSettingsDeeplinkOption)
    func showToast(message: String)
}
// swiftlint:enable class_delegate_protocol

extension HomepageContextMenuHelperDelegate {
    func homePanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool, selectNewTab: Bool = false) {
        homePanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }
}

class HomepageContextMenuHelper: HomepageContextMenuProtocol {
    typealias ContextHelperDelegate = HomepageContextMenuHelperDelegate & UIPopoverPresentationControllerDelegate
    typealias SendToDeviceDelegate = InstructionsViewDelegate & DevicePickerViewControllerDelegate
    private var viewModel: HomepageViewModel
    private let toastContainer: UIView
    weak var sendToDeviceDelegate: SendToDeviceDelegate?
    weak var browserNavigationHandler: BrowserNavigationHandler?
    weak var delegate: ContextHelperDelegate?
    var getPopoverSourceRect: ((UIView?) -> CGRect)?

    init(
        viewModel: HomepageViewModel,
        toastContainer: UIView
    ) {
        self.viewModel = viewModel
        self.toastContainer = toastContainer
    }

    func presentContextMenu(for site: Site,
                            with sourceView: UIView?,
                            sectionType: HomepageSectionType,
                            completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        fetchBookmarkStatus(for: site) {
            guard let contextMenu = completionHandler() else { return }
            self.delegate?.present(contextMenu, animated: true, completion: nil)
        }
    }

    func getContextMenuActions(for site: Site, with sourceView: UIView?, sectionType: HomepageSectionType) -> [PhotonRowActions]? {
        var actions = [PhotonRowActions]()
        if sectionType == .topSites, let topSitesActions = getTopSitesActions(site: site) {
            actions = topSitesActions
        } else if sectionType == .pocket, let pocketActions = getPocketActions(site: site, with: sourceView) {
            actions = pocketActions
        }

        return actions
    }

    func presentContextMenu(for highlightItem: HighlightItem,
                            with sourceView: UIView?,
                            sectionType: HomepageSectionType,
                            completionHandler: @escaping () -> PhotonActionSheet?
    ) {
        guard let contextMenu = completionHandler() else { return }
        delegate?.present(contextMenu, animated: true, completion: nil)
    }

    func getContextMenuActions(for highlightItem: HighlightItem,
                               with sourceView: UIView?,
                               sectionType: HomepageSectionType
    ) -> [PhotonRowActions]? {
        guard sectionType == .historyHighlights,
              let highlightsActions = getHistoryHighlightsActions(for: highlightItem)
        else { return nil }

        return highlightsActions
    }

    // MARK: - Default actions
    func getOpenInNewPrivateTabAction(siteURL: URL, sectionType: HomepageSectionType) -> PhotonRowActions {
        return SingleActionViewModel(title: .OpenInNewPrivateTabContextMenuTitle, iconString: ImageIdentifiers.newPrivateTab) { _ in
            self.delegate?.homePanelDidRequestToOpenInNewTab(siteURL, isPrivate: true)
            sectionType.newPrivateTabActionTelemetry()
        }.items
    }

    // MARK: - History Highlights

    private func getHistoryHighlightsActions(for highlightItem: HighlightItem) -> [PhotonRowActions]? {
        return [SingleActionViewModel(title: .RemoveContextMenuTitle,
                                      iconString: StandardImageIdentifiers.Large.cross,
                                      tapHandler: { _ in
            self.viewModel.historyHighlightsViewModel.delete(highlightItem)
            self.sendHistoryHighlightContextualTelemetry(type: .remove)
        }).items]
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
        return SingleActionViewModel(title: .OpenInNewTabContextMenuTitle, iconString: StandardImageIdentifiers.Large.plus) { _ in
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
        if site.bookmarked ?? false {
            bookmarkAction = getRemoveBookmarkAction(site: site)
        } else {
            bookmarkAction = getAddBookmarkAction(site: site)
        }
        return bookmarkAction.items
    }

    private func getRemoveBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .RemoveBookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmarkSlash,
                                     tapHandler: { _ in
            self.viewModel.profile.places.deleteBookmarksWithURL(url: site.url) >>== {
                site.setBookmarked(false)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .activityStream)
        })
    }

    private func getAddBookmarkAction(site: Site) -> SingleActionViewModel {
        return SingleActionViewModel(title: .BookmarkContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.bookmark,
                                     tapHandler: { _ in
            let shareItem = ShareItem(url: site.url, title: site.title)
            // Add new mobile bookmark at the top of the list
            _ = self.viewModel.profile.places.createBookmark(parentGUID: BookmarkRoots.MobileFolderGUID,
                                                             url: shareItem.url,
                                                             title: shareItem.title,
                                                             position: 0)

            var userData = [QuickActionInfos.tabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActionInfos.tabTitleKey] = title
            }
            QuickActionsImplementation().addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                 withUserData: userData,
                                                                                 toApplication: .shared)
            site.setBookmarked(true)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .activityStream)
        })
    }

    /// Handles share from Long press on Pocket article
    /// - Parameters:
    ///   - site: Site for pocket article
    ///   - sourceView: View to show the popover
    /// - Returns: Share action
    private func getShareAction(site: Site, sourceView: UIView?) -> PhotonRowActions {
        return SingleActionViewModel(title: .ShareContextMenuTitle, iconString: ImageIdentifiers.share, tapHandler: { _ in
            guard let url = URL(string: site.url) else { return }

            if CoordinatorFlagManager.isShareExtensionCoordinatorEnabled {
                self.browserNavigationHandler?.showShareExtension(
                    url: url,
                    sourceView: sourceView ?? UIView(),
                    toastContainer: self.toastContainer,
                    popoverArrowDirection: [.up, .down, .left])
            } else {
                let helper = ShareExtensionHelper(url: url, tab: nil)
                let controller = helper.createActivityViewController { (_, activityType) in
                    switch activityType {
                    case CustomActivityAction.sendToDevice.actionType:
                        self.showSendToDevice(site: site)
                    case CustomActivityAction.copyLink.actionType:
                        self.delegate?.showToast(message: .AppMenu.AppMenuCopyURLConfirmMessage)
                    default: break
                    }
                }

                if UIDevice.current.userInterfaceIdiom == .pad,
                   let popoverController = controller.popoverPresentationController,
                   let getSourceRect = self.getPopoverSourceRect {
                    popoverController.sourceView = sourceView
                    popoverController.sourceRect = getSourceRect(sourceView)
                    popoverController.permittedArrowDirections = [.up, .down, .left]
                    popoverController.delegate = self.delegate
                }

                self.delegate?.presentWithModalDismissIfNeeded(controller, animated: true)
            }
        }).items
    }

    private func showSendToDevice(site: Site) {
        guard let delegate = sendToDeviceDelegate else { return }

        let themeColors = viewModel.theme.colors

        let colors = SendToDeviceHelper.Colors(defaultBackground: themeColors.layer1,
                                               textColor: themeColors.textPrimary,
                                               iconColor: themeColors.iconPrimary)
        let shareItem = ShareItem(url: site.url, title: site.title)
        let helper = SendToDeviceHelper(shareItem: shareItem,
                                        profile: viewModel.profile,
                                        colors: colors,
                                        delegate: delegate)
        let viewController = helper.initialViewController()

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
        self.delegate?.presentWithModalDismissIfNeeded(viewController, animated: true)
    }

    // MARK: - Top sites

    func getTopSitesActions(site: Site) -> [PhotonRowActions]? {
        guard let siteURL = site.url.asURL else { return nil }

        let topSiteActions: [PhotonRowActions]
        if let site = site as? PinnedSite {
            topSiteActions = [getRemovePinTopSiteAction(site: site),
                              getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getRemoveTopSiteAction(site: site)]
        } else if site as? SponsoredTile != nil {
            topSiteActions = [getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getSettingsAction(),
                              getSponsoredContentAction()]
        } else {
            topSiteActions = [getPinTopSiteAction(site: site),
                              getOpenInNewPrivateTabAction(siteURL: siteURL, sectionType: .topSites),
                              getRemoveTopSiteAction(site: site)]
        }
        return topSiteActions
    }

    // Removes the site out of the top sites. If site is pinned it removes it from pinned and remove
    private func getRemoveTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .RemoveContextMenuTitle,
                                     iconString: StandardImageIdentifiers.Large.cross,
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
                                     tapHandler: { _ in
            self.viewModel.topSiteViewModel.pinTopSite(site)
            self.sendTopSiteContextualTelemetry(type: .pin)
        }).items
    }

    // Unpin removes it from the location it's in. Still can appear in the top sites as unpin
    private func getRemovePinTopSiteAction(site: Site) -> PhotonRowActions {
        return SingleActionViewModel(title: .UnpinTopsiteActionTitle2,
                                     iconString: StandardImageIdentifiers.Large.pinSlash,
                                     tapHandler: { _ in
            self.viewModel.topSiteViewModel.removePinTopSite(site)
            self.sendTopSiteContextualTelemetry(type: .unpin)
        }).items
    }

    private func getSettingsAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.Settings, iconString: ImageIdentifiers.settings, tapHandler: { _ in
            self.delegate?.homePanelDidRequestToOpenSettings(at: .customizeTopSites)
            self.sendTopSiteContextualTelemetry(type: .settings)
        }).items
    }

    private func getSponsoredContentAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
                                     iconString: StandardImageIdentifiers.Large.helpCircle,
                                     tapHandler: { _ in
            guard let url = SupportUtils.URLForTopic("sponsor-privacy") else { return }
            self.delegate?.homePanelDidRequestToOpenInNewTab(url, isPrivate: false, selectNewTab: true)
            self.sendTopSiteContextualTelemetry(type: .sponsoredSupport)
        }).items
    }

    private func fetchBookmarkStatus(for site: Site, completionHandler: @escaping () -> Void) {
        viewModel.profile.places.isBookmarked(url: site.url).uponQueue(.main) { result in
            let isBookmarked = result.successValue ?? false
            site.setBookmarked(isBookmarked)
            completionHandler()
        }
    }

    // MARK: Telemetry

    enum ContextualActionType: String {
        case remove, unpin, pin, settings, sponsoredSupport
    }

    private func sendTopSiteContextualTelemetry(type: ContextualActionType) {
        let extras = [TelemetryWrapper.EventExtraKey.contextualMenuType.rawValue: type.rawValue]
        TelemetryWrapper.recordEvent(category: .action, method: .view, object: .topSiteContextualMenu, value: nil, extras: extras)
    }

    func sendHistoryHighlightContextualTelemetry(type: ContextualActionType) {
        let extras = [TelemetryWrapper.EventExtraKey.contextualMenuType.rawValue: type.rawValue]
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .view,
                                     object: .historyHighlightContextualMenu,
                                     value: nil,
                                     extras: extras)
    }
}
