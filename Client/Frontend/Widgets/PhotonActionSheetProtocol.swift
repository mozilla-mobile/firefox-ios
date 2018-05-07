/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import Deferred

protocol PhotonActionSheetProtocol {
    var tabManager: TabManager { get }
    var profile: Profile { get }
}

private let log = Logger.browserLogger

extension PhotonActionSheetProtocol {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate
    typealias MenuAction = () -> Void
    typealias IsPrivateTab = Bool
    typealias URLOpenAction = (URL?, IsPrivateTab) -> Void
    
    func presentSheetWith(title: String? = nil, actions: [[PhotonActionSheetItem]], on viewController: PresentableVC, from view: UIView, closeButtonTitle: String = Strings.CloseButtonTitle, suppressPopover: Bool = false) {
        let style: UIModalPresentationStyle = (UIDevice.current.userInterfaceIdiom == .pad && !suppressPopover) ? .popover : .overCurrentContext
        let sheet = PhotonActionSheet(title: title, actions: actions, closeButtonTitle: closeButtonTitle, style: style)
        sheet.modalPresentationStyle = style
        sheet.photonTransitionDelegate = PhotonActionSheetAnimator()
        
        if let popoverVC = sheet.popoverPresentationController, sheet.modalPresentationStyle == .popover {
            popoverVC.delegate = viewController
            popoverVC.sourceView = view
            popoverVC.sourceRect = CGRect(x: view.frame.width/2, y: view.frame.size.height * 0.75, width: 1, height: 1)
            popoverVC.permittedArrowDirections = .up
            popoverVC.backgroundColor = UIConstants.AppBackgroundColor.withAlphaComponent(0.7)
        }
        viewController.present(sheet, animated: true, completion: nil)
    }
    
    //Returns a list of actions which is used to build a menu
    //OpenURL is a closure that can open a given URL in some view controller. It is up to the class using the menu to know how to open it
    func getHomePanelActions() -> [PhotonActionSheetItem] {
        guard let tab = self.tabManager.selectedTab else { return [] }

        let openTopSites = PhotonActionSheetItem(title: Strings.AppMenuTopSitesTitleString, iconString: "menu-panel-TopSites") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.topSites.localhostURL) as URLRequest)
        }

        let openBookmarks = PhotonActionSheetItem(title: Strings.AppMenuBookmarksTitleString, iconString: "menu-panel-Bookmarks") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.bookmarks.localhostURL) as URLRequest)
            UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .bookmarksPanel, value: .appMenu)
        }

        let openReadingList = PhotonActionSheetItem(title: Strings.AppMenuReadingListTitleString, iconString: "menu-panel-ReadingList") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.readingList.localhostURL) as URLRequest)
        }

        let openHistory = PhotonActionSheetItem(title: Strings.AppMenuHistoryTitleString, iconString: "menu-panel-History") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.history.localhostURL) as URLRequest)
        }

        let openDownloads = PhotonActionSheetItem(title: Strings.AppMenuDownloadsTitleString, iconString: "menu-panel-Downloads") { action in
            tab.loadRequest(PrivilegedRequest(url: HomePanelType.downloads.localhostURL) as URLRequest)
            UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .downloadsPanel, value: .appMenu)
        }

        let openHomePage = PhotonActionSheetItem(title: Strings.AppMenuOpenHomePageTitleString, iconString: "menu-Home") { _ in
            HomePageHelper(prefs: self.profile.prefs).openHomePage(tab)
        }
        
        var actions = [openTopSites, openBookmarks, openReadingList, openHistory, openDownloads]
        if HomePageHelper(prefs: self.profile.prefs).isHomePageAvailable {
            actions.insert(openHomePage, at: 0)
        }

        return actions
    }
    
    /*
     Returns a list of actions which is used to build the general browser menu
     These items repersent global options that are presented in the menu
     TODO: These icons should all have the icons and use Strings.swift
     */
    
    typealias PageOptionsVC = QRCodeViewControllerDelegate & SettingsDelegate & PresentingModalViewControllerDelegate & UIViewController
    
    func getOtherPanelActions(vcDelegate: PageOptionsVC) -> [PhotonActionSheetItem] {
        var items: [PhotonActionSheetItem] = []

        if #available(iOS 11, *) {
            let noImageEnabled = NoImageModeHelper.isActivated(profile.prefs)
            let noImageMode = PhotonActionSheetItem(title: Strings.AppMenuNoImageMode, iconString: "menu-NoImageMode", isEnabled: noImageEnabled, accessory: .Switch) { action in
                NoImageModeHelper.toggle(profile: self.profile, tabManager: self.tabManager)
            }

            let trackingProtectionEnabled = ContentBlockerHelper.isTrackingProtectionActive(tabManager: self.tabManager)
            let trackingProtection = PhotonActionSheetItem(title: Strings.TPMenuTitle, iconString: "menu-TrackingProtection", isEnabled: trackingProtectionEnabled, accessory: .Switch) { action in
                ContentBlockerHelper.toggleTrackingProtectionMode(for: self.profile.prefs, tabManager: self.tabManager)
            }
            items.append(contentsOf: [trackingProtection, noImageMode])
        }

        let nightModeEnabled = NightModeHelper.isActivated(profile.prefs)
        let nightMode = PhotonActionSheetItem(title: Strings.AppMenuNightMode, iconString: "menu-NightMode", isEnabled: nightModeEnabled, accessory: .Switch) { action in
            NightModeHelper.toggle(self.profile.prefs, tabManager: self.tabManager)
        }
        items.append(nightMode)

        let openSettings = PhotonActionSheetItem(title: Strings.AppMenuSettingsTitleString, iconString: "menu-Settings") { action in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = vcDelegate

            let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
            controller.popoverDelegate = vcDelegate
            controller.modalPresentationStyle = .formSheet
            vcDelegate.present(controller, animated: true, completion: nil)
        }
        items.append(openSettings)

        return items
    }
    
    func getTabActions(tab: Tab, buttonView: UIView,
                       presentShareMenu: @escaping (URL, Tab, UIView, UIPopoverArrowDirection) -> Void,
                       findInPage:  @escaping () -> Void,
                       presentableVC: PresentableVC,
                       isBookmarked: Bool,
                       isPinned: Bool,
                       success: @escaping (String) -> Void) -> Array<[PhotonActionSheetItem]> {
        
        let toggleActionTitle = tab.desktopSite ? Strings.AppMenuViewMobileSiteTitleString : Strings.AppMenuViewDesktopSiteTitleString
        let toggleDesktopSite = PhotonActionSheetItem(title: toggleActionTitle, iconString: "menu-RequestDesktopSite") { action in
            tab.toggleDesktopSite()
        }
        
        let addReadingList = PhotonActionSheetItem(title: Strings.AppMenuAddToReadingListTitleString, iconString: "addToReadingList") { action in
            guard let url = tab.url?.displayURL else { return }

            self.profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            UnifiedTelemetry.recordEvent(category: .action, method: .add, object: .readingListItem, value: .pageActionMenu)
            success(Strings.AppMenuAddToReadingListConfirmMessage)
        }

        let findInPageAction = PhotonActionSheetItem(title: Strings.AppMenuFindInPageTitleString, iconString: "menu-FindInPage") { action in
            findInPage()
        }

        let bookmarkPage = PhotonActionSheetItem(title: Strings.AppMenuAddBookmarkTitleString, iconString: "menu-Bookmark") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.canonicalURL?.displayURL else { return }
            let absoluteString = url.absoluteString
            let shareItem = ShareItem(url: absoluteString, title: tab.title, favicon: tab.displayFavicon)
            _ = self.profile.bookmarks.shareItem(shareItem)
            var userData = [QuickActions.TabURLKey: shareItem.url]
            if let title = shareItem.title {
                userData[QuickActions.TabTitleKey] = title
            }
            QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark,
                                                                                withUserData: userData,
                                                                                toApplication: .shared)
            UnifiedTelemetry.recordEvent(category: .action, method: .add, object: .bookmark, value: .pageActionMenu)
            success(Strings.AppMenuAddBookmarkConfirmMessage)
        }
        
        let removeBookmark = PhotonActionSheetItem(title: Strings.AppMenuRemoveBookmarkTitleString, iconString: "menu-Bookmark-Remove") { action in
            //TODO: can all this logic go somewhere else?
            guard let url = tab.url?.displayURL else { return }
            let absoluteString = url.absoluteString
            self.profile.bookmarks.modelFactory >>== {
                $0.removeByURL(absoluteString).uponQueue(.main) { res in
                    if res.isSuccess {
                        UnifiedTelemetry.recordEvent(category: .action, method: .delete, object: .bookmark, value: .pageActionMenu)
                        success(Strings.AppMenuRemoveBookmarkConfirmMessage)
                    }
                }
            }
        }
        
        let pinToTopSites = PhotonActionSheetItem(title: Strings.PinTopsiteActionTitle, iconString: "action_pin") { action in
            guard let url = tab.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }
            
            sql.getSitesForURLs([url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }

                return self.profile.history.addPinnedTopSite(site)
                }.uponQueue(.main) { _ in }
        }

        let removeTopSitesPin = PhotonActionSheetItem(title: Strings.RemovePinTopsiteActionTitle, iconString: "action_unpin") { action in
            guard let url = tab.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }

            sql.getSitesForURLs([url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }

                return self.profile.history.removeFromPinnedTopSites(site)
            }.uponQueue(.main) { _ in }
        }

        let sendToDevice = PhotonActionSheetItem(title: Strings.SendToDeviceTitle, iconString: "menu-Send-to-Device") { action in
            guard let bvc = presentableVC as? PresentableVC & InstructionsViewControllerDelegate & ClientPickerViewControllerDelegate else { return }
            if !self.profile.hasAccount() {
                let instructionsViewController = InstructionsViewController()
                instructionsViewController.delegate = bvc
                let navigationController = UINavigationController(rootViewController: instructionsViewController)
                navigationController.modalPresentationStyle = .formSheet
                bvc.present(navigationController, animated: true, completion: nil)
                return
            }

            let clientPickerViewController = ClientPickerViewController()
            clientPickerViewController.clientPickerDelegate = bvc
            clientPickerViewController.profile = self.profile
            clientPickerViewController.profileNeedsShutdown = false
            let navigationController = UINavigationController(rootViewController: clientPickerViewController)
            navigationController.modalPresentationStyle = .formSheet
            bvc.present(navigationController, animated: true, completion: nil)
        }
        
        let share = PhotonActionSheetItem(title: Strings.AppMenuSharePageTitleString, iconString: "action_share") { action in
            guard let url = tab.canonicalURL?.displayURL else { return }
            presentShareMenu(url, tab, buttonView, .up)
        }

        let copyURL = PhotonActionSheetItem(title: Strings.AppMenuCopyURLTitleString, iconString: "menu-Copy-Link") { _ in
            UIPasteboard.general.url = tab.canonicalURL?.displayURL
            success(Strings.AppMenuCopyURLConfirmMessage)
        }

        var mainActions = [share]

        // Disable bookmarking and reading list if the URL is too long.
        if !tab.urlIsTooLong {
            mainActions.append(isBookmarked ? removeBookmark : bookmarkPage)

            if tab.readerModeAvailableOrActive {
                mainActions.append(addReadingList)
            }
        }

        let pinAction = (isPinned ? removeTopSitesPin : pinToTopSites)
        mainActions.append(contentsOf: [sendToDevice, copyURL])

        return [mainActions, [findInPageAction, toggleDesktopSite, pinAction]]
    }

    func fetchBookmarkStatus(for url: String) -> Deferred<Maybe<Bool>> {
        return self.profile.bookmarks.modelFactory.bind {
            guard let factory = $0.successValue else {
                return deferMaybe(false)
            }
            return factory.isBookmarked(url)
        }
    }

    func fetchPinnedTopSiteStatus(for url: String) -> Deferred<Maybe<Bool>> {
        return self.profile.history.isPinnedTopSite(url)
    }

    func getLongPressLocationBarActions(with urlBar: URLBarView) -> [PhotonActionSheetItem] {
        let pasteGoAction = PhotonActionSheetItem(title: Strings.PasteAndGoTitle, iconString: "menu-PasteAndGo") { action in
            if let pasteboardContents = UIPasteboard.general.string {
                urlBar.delegate?.urlBar(urlBar, didSubmitText: pasteboardContents)
            }
        }
        let pasteAction = PhotonActionSheetItem(title: Strings.PasteTitle, iconString: "menu-Paste") { action in
            if let pasteboardContents = UIPasteboard.general.string {
                urlBar.enterOverlayMode(pasteboardContents, pasted: true, search: true)
            }
        }
        let copyAddressAction = PhotonActionSheetItem(title: Strings.CopyAddressTitle, iconString: "menu-Copy-Link") { action in
            if let url = urlBar.currentURL {
                UIPasteboard.general.url = url as URL
            }
        }
        if UIPasteboard.general.string != nil {
            return [pasteGoAction, pasteAction, copyAddressAction]
        } else {
            return [copyAddressAction]
        }
    }

    @available(iOS 11.0, *)
    private func menuActionsForNotBlocking() -> [PhotonActionSheetItem] {
        return [PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TPNoBlockingDescription, iconString: "menu-TrackingProtection")]
    }

    @available(iOS 11.0, *)
    private func menuActionsForTrackingProtectionDisabled(for tab: Tab) -> [[PhotonActionSheetItem]] {
        let enableTP = PhotonActionSheetItem(title: Strings.EnableTPBlocking, iconString: "menu-TrackingProtection") { _ in
            // When TP is off for the tab tapping enable in this menu should turn it back on for the Tab.
            if let blocker = tab.contentBlocker as? ContentBlockerHelper, blocker.isUserEnabled == false {
                blocker.isUserEnabled = true
            } else {
                ContentBlockerHelper.toggleTrackingProtectionMode(for: self.profile.prefs, tabManager: self.tabManager)
            }
            tab.reload()
        }

        let moreInfo = PhotonActionSheetItem(title: Strings.TPBlockingMoreInfo, iconString: "menu-Info") { _ in
            let url = SupportUtils.URLForTopic("tracking-protection-ios")!
            tab.loadRequest(PrivilegedRequest(url: url) as URLRequest)
        }
        return [[moreInfo], [enableTP]]
    }

    @available(iOS 11.0, *)
    private func menuActionsForTrackingProtectionEnabled(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let blocker = tab.contentBlocker as? ContentBlockerHelper, let currentURL = tab.url else {
            return []
        }

        let stats = blocker.stats
        let totalCount = PhotonActionSheetItem(title: Strings.TrackingProtectionTotalBlocked, accessory: .Text, accessoryText: "\(stats.total)", bold: true)
        let adCount = PhotonActionSheetItem(title: Strings.TrackingProtectionAdsBlocked, accessory: .Text, accessoryText: "\(stats.adCount)")
        let analyticsCount = PhotonActionSheetItem(title: Strings.TrackingProtectionAnalyticsBlocked, accessory: .Text, accessoryText: "\(stats.analyticCount)")
        let socialCount = PhotonActionSheetItem(title: Strings.TrackingProtectionSocialBlocked, accessory: .Text, accessoryText: "\(stats.socialCount)")
        let contentCount = PhotonActionSheetItem(title: Strings.TrackingProtectionContentBlocked, accessory: .Text, accessoryText: "\(stats.contentCount)")
        let statList = [totalCount, adCount, analyticsCount, socialCount, contentCount]

        let addToWhitelist = PhotonActionSheetItem(title: Strings.TrackingProtectionDisableTitle, iconString: "menu-TrackingProtection-Off") { _ in
            UnifiedTelemetry.recordEvent(category: .action, method: .add, object: .trackingProtectionWhitelist)
            ContentBlockerHelper.whitelist(enable: true, url: currentURL) {
                tab.reload()
            }
        }
        return [statList, [addToWhitelist]]
    }

    @available(iOS 11.0, *)
    private func menuActionsForWhitelistedSite(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let currentURL = tab.url else {
            return []
        }

        let removeFromWhitelist = PhotonActionSheetItem(title: Strings.TrackingProtectionWhiteListRemove, iconString: "menu-TrackingProtection") { _ in
            ContentBlockerHelper.whitelist(enable: false, url: currentURL) {
                tab.reload()
            }
        }
        return [[removeFromWhitelist]]
    }

    @available(iOS 11.0, *)
    func getTrackingMenu(for tab: Tab, presentingOn urlBar: URLBarView) -> [PhotonActionSheetItem] {
        guard let blocker = tab.contentBlocker as? ContentBlockerHelper else {
            return []
        }

        switch blocker.status {
        case .NoBlockedURLs:
            return menuActionsForNotBlocking()
        case .Blocking:
            let actions = menuActionsForTrackingProtectionEnabled(for: tab)
            let tpBlocking = PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TPBlockingDescription, iconString: "menu-TrackingProtection", isEnabled: false, accessory: .Disclosure) { _ in
                guard let bvc = self as? PresentableVC else { return }
                UnifiedTelemetry.recordEvent(category: .action, method: .view, object: .trackingProtectionStatistics)
                self.presentSheetWith(title: Strings.SettingsTrackingProtectionSectionName, actions: actions, on: bvc, from: urlBar)
            }
            return [tpBlocking]
        case .Disabled:
            let actions = menuActionsForTrackingProtectionDisabled(for: tab)
            let tpBlocking = PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TPBlockingDisabledDescription, iconString: "menu-TrackingProtection", isEnabled: false, accessory: .Disclosure) { _ in
                guard let bvc = self as? PresentableVC else { return }
                self.presentSheetWith(title: Strings.SettingsTrackingProtectionSectionName, actions: actions, on: bvc, from: urlBar)
            }
            return  [tpBlocking]
        case .Whitelisted:
            let actions = self.menuActionsForWhitelistedSite(for: tab)
            let tpBlocking = PhotonActionSheetItem(title: Strings.SettingsTrackingProtectionSectionName, text: Strings.TrackingProtectionWhiteListOn, iconString: "menu-TrackingProtection-Off", isEnabled: false, accessory: .Disclosure) { _ in
                guard let bvc = self as? PresentableVC else { return }
                self.presentSheetWith(title: Strings.SettingsTrackingProtectionSectionName, actions: actions, on: bvc, from: urlBar)
            }
            return [tpBlocking]
        }
    }

    @available(iOS 11.0, *)
    func getTrackingSubMenu(for tab: Tab) -> [[PhotonActionSheetItem]] {
        guard let blocker = tab.contentBlocker as? ContentBlockerHelper else {
            return []
        }
        switch blocker.status {
        case .NoBlockedURLs:
            return []
        case .Blocking:
            return menuActionsForTrackingProtectionEnabled(for: tab)
        case .Disabled:
            return menuActionsForTrackingProtectionDisabled(for: tab)
        case .Whitelisted:
            return menuActionsForWhitelistedSite(for: tab)
        }
    }

    func getRefreshLongPressMenu(for tab: Tab) -> [PhotonActionSheetItem] {
        guard tab.webView?.url != nil && (tab.getContentScript(name: ReaderMode.name()) as? ReaderMode)?.state != .active else {
            return []
        }

        let toggleActionTitle = tab.desktopSite ? Strings.AppMenuViewMobileSiteTitleString : Strings.AppMenuViewDesktopSiteTitleString
        let toggleDesktopSite = PhotonActionSheetItem(title: toggleActionTitle, iconString: "menu-RequestDesktopSite") { action in
            tab.toggleDesktopSite()
        }

        if #available(iOS 11, *), let helper = tab.contentBlocker as? ContentBlockerHelper {
            let title = helper.isEnabled ? Strings.TrackingProtectionReloadWithout : Strings.TrackingProtectionReloadWith
            let imageName = helper.isEnabled ? "menu-TrackingProtection-Off" : "menu-TrackingProtection"
            let toggleTP = PhotonActionSheetItem(title: title, iconString: imageName) { action in
                helper.isUserEnabled = !helper.isEnabled
            }
            return [toggleDesktopSite, toggleTP]
        } else {
            return [toggleDesktopSite]
        }
    }

    func syncMenuButton(showFxA: @escaping (_ params: FxALaunchParams?) -> ()) -> [PhotonActionSheetItem]? {
        profile.getAccount()?.updateProfile()
        let account = profile.getAccount()

        func title() -> String? {
            guard let status = account?.actionNeeded else { return Strings.FxASignInToSync }
            switch status {
            case .none:
                return account?.fxaProfile?.displayName ?? account?.fxaProfile?.email
            case .needsVerification:
                return Strings.FxAAccountVerifyEmail
            case .needsPassword:
                return Strings.FxAAccountVerifyPassword
            case .needsUpgrade:
                return Strings.FxAAccountUpgradeFirefox
            }
        }

        func imageName() -> String? {
            guard let status = account?.actionNeeded else { return "menu-sync" }
            switch status {
            case .none:
                return "placeholder-avatar"
            case .needsVerification, .needsPassword, .needsUpgrade:
                return "menu-warning"
            }
        }

        let action: ((PhotonActionSheetItem) -> Void) = { action in
            let fxaParams = FxALaunchParams(query: ["entrypoint": "browsermenu"])
            showFxA(fxaParams)
        }

        guard let title = title(), let iconString = imageName() else { return nil }
        // .none is also a case on the swift enum "Optional" so the value needs to be unwrapped before we check
        var iconURL: URL? = nil
        if let actionNeeded = account?.actionNeeded {
            iconURL = (actionNeeded == .none) ? account?.fxaProfile?.avatar.url : nil
        }
        let syncOption = PhotonActionSheetItem(title: title, iconString: iconString, iconURL: iconURL, handler: action)
        return [syncOption]
    }
}
