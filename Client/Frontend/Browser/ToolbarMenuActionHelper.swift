// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit
import Storage

protocol ToolBarActionMenuDelegate: AnyObject {
    func updateToolbarState()
    func addBookmark(url: String, title: String?, favicon: Favicon?)

    func openURLInNewTab(_ url: URL?, isPrivate: Bool)
    func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool, searchFor searchText: String?)

    func showLibrary(panel: LibraryPanelType?)
    func showViewController(viewController: UIViewController)
    func showToast(message: String, toastAction: MenuButtonToastAction, url: String?)
    func showMenuPresenter(url: URL, tab: Tab, view: UIView)
    func showFindInPage()
    func showCustomizeHomePage()
}

enum MenuButtonToastAction {
    case share
    case addToReadingList
    case bookmarkPage
    case removeBookmark
    case copyUrl
    case pinPage
    case removePinPage
}

typealias FXAClosureType = (params: FxALaunchParams?, flowType: FxAPageType, referringPage: ReferringPage)
class ToolbarMenuActionHelper: PhotonActionSheetProtocol, FeatureFlagsProtocol {

    private let isHomePage: Bool
    private let buttonView: UIButton
    private let selectedTab: Tab?
    private let tabUrl: URL?
    private let isFileURL: Bool

    let profile: Profile
    let tabManager: TabManager

    weak var delegate: ToolBarActionMenuDelegate?
    weak var menuActionDelegate: MenuActionsDelegate?

    var showFXAClosure: (FXAClosureType) -> Void

    init(profile: Profile,
         isHomePage: Bool,
         tabManager: TabManager,
         buttonView: UIButton,
         showFXAClosure: @escaping (FXAClosureType) -> Void) {

        self.profile = profile
        self.isHomePage = isHomePage
        self.tabManager = tabManager
        self.buttonView = buttonView
        self.showFXAClosure = showFXAClosure

        self.selectedTab = tabManager.selectedTab
        self.tabUrl = selectedTab?.url
        self.isFileURL = tabUrl?.isFileURL ?? false
    }

    func getToolbarActions(navigationController: UINavigationController?,
                           completion: @escaping ([[PhotonActionSheetItem]]) -> Void) {
        var actions: [[PhotonActionSheetItem]] = []
        let firstMiscSection = getFirstMiscSection(navigationController)

        if isHomePage {
            actions.append(contentsOf: [getLibrarySection(),
                                        firstMiscSection,
                                        getLastSection()])
            completion(actions)

        } else {

            // Actions on site page need specific data to be loaded
            updateData(dataLoadingCompletion: {
                actions.append(contentsOf: [self.getNewTabSection(),
                                            self.getLibrarySection(),
                                            firstMiscSection,
                                            self.getSecondMiscSection(),
                                            self.getLastSection()])

                DispatchQueue.main.async {
                    completion(actions)
                }
            })
        }
    }

    // MARK: - Update data

    private let dataQueue = DispatchQueue(label: "com.moz.toolbarMenuAction.queue")

    /// Update data to show the proper menus related to the page
    /// - Parameter dataLoadingCompletion: Complete when the loading of data from the profile is done
    private func updateData(dataLoadingCompletion: (() -> Void)? = nil) {
        guard let url = tabUrl?.absoluteString else { dataLoadingCompletion?(); return }

        let group = DispatchGroup()
        getIsBookmarked(url: url, group: group)
        getIsPinned(url: url, group: group)

        let dataQueue = DispatchQueue.global(qos: .userInitiated)
        group.notify(queue: dataQueue) {
            dataLoadingCompletion?()
        }
    }

    private var isBookmarked: Bool?
    private func getIsBookmarked(url: String, group: DispatchGroup) {
        group.enter()
        profile.places.isBookmarked(url: url).uponQueue(.main) { result in
            self.isBookmarked = result.successValue ?? false
            group.leave()
        }
    }

    private var isPinned: Bool?
    private func getIsPinned(url: String, group: DispatchGroup) {
        group.enter()
        profile.history.isPinnedTopSite(url).uponQueue(.main) { result in
            self.isPinned = result.successValue ?? false
            group.leave()
        }
    }

    // MARK: - Sections

    private func getNewTabSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()
        let newTabAction = PhotonActionSheetItem(title: .KeyboardShortcuts.NewTab,
                                                 iconString: "quick_action_new_tab",
                                                 isEnabled: true) { _, _ in

            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.delegate?.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false, searchFor: nil)
        }
        append(to: &section, action: newTabAction)

        return section
    }

    private func getLibrarySection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        if !isFileURL {
            let bookmarkSection = getBookmarkSection()
            append(to: &section, action: bookmarkSection)

            let historySection = getHistoryLibraryAction()
            append(to: &section, action: historySection)

            let downloadSection = getDownloadsLibraryAction()
            append(to: &section, action: downloadSection)

            let readingListSection = getReadingListSection()
            append(to: &section, action: readingListSection)
        }

        // TODO: laurie - Double check show email adress properly
        let syncAction = syncMenuButton(showFxA: showFXAClosure)
        append(to: &section, action: syncAction)

        return section
    }

    private func getFirstMiscSection(_ navigationController: UINavigationController?) -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        if !isHomePage && !isFileURL {
            let findInPageAction = getFindInPageAction()
            append(to: &section, action: findInPageAction)

            let desktopSiteAction = getRequestDesktopSiteAction()
            append(to: &section, action: desktopSiteAction)
        }

        let nightModeAction = getNightModeAction()
        append(to: &section, action: nightModeAction)

        if let navigationController = navigationController {
            let passwordsAction = getPasswordAction(navigationController: navigationController)
            append(to: &section, action: passwordsAction)
        }

        if !isHomePage && !isFileURL {
            let reportSiteIssueAction = getReportSiteIssueAction()
            append(to: &section, action: reportSiteIssueAction)
        }

        return section
    }

    private func getSecondMiscSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        if isFileURL {
            let shareFileAction = getShareFileAction()
            append(to: &section, action: shareFileAction)
        } else {
            let shortAction = getShortcutAction()
            append(to: &section, action: shortAction)

            let copyAction = getCopyAction()
            append(to: &section, action: copyAction)

            let sendToDeviceAction = getSendToDevice()
            append(to: &section, action: sendToDeviceAction)

            let shareAction = getShareAction()
            append(to: &section, action: shareAction)
        }

        return section
    }

    private func getLastSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        if isHomePage {
            let whatsNewAction = getWhatsNewAction()
            append(to: &section, action: whatsNewAction)

            let helpAction = getHelpAction()
            section.append(helpAction)

            let customizeHomePageAction = getCustomizeHomePageAction()
            append(to: &section, action: customizeHomePageAction)
        }

        let settingsAction = getSettingsAction(vcDelegate: menuActionDelegate)
        section.append(settingsAction)

        return section
    }

    // MARK: - Actions

    private func getHistoryLibraryAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuHistory,
                                     iconString: "menu-panel-History") { _, _ in
            self.delegate?.showLibrary(panel: .history)
        }
    }

    private func getDownloadsLibraryAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuDownloads, iconString: "menu-panel-Downloads") { _, _ in
            self.delegate?.showLibrary(panel: .downloads)
        }
    }

    private func getFindInPageAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuFindInPageTitleString,
                                     iconString: "menu-FindInPage") { _, _ in
            self.delegate?.showFindInPage()
        }
    }

    private func getRequestDesktopSiteAction() -> PhotonActionSheetItem? {
        guard let tab = selectedTab else { return nil }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        let toggleActionIcon: String
        let siteTypeTelemetryObject: TelemetryWrapper.EventObject
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .AppMenuViewDesktopSiteTitleString : .AppMenuViewMobileSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? "menu-RequestDesktopSite" : "menu-ViewMobile"
            siteTypeTelemetryObject = .requestDesktopSite
        } else {
            toggleActionTitle = tab.changedUserAgent ? .AppMenuViewMobileSiteTitleString : .AppMenuViewDesktopSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? "menu-ViewMobile" : "menu-RequestDesktopSite"
            siteTypeTelemetryObject = .requestMobileSite
        }

        return PhotonActionSheetItem(title: toggleActionTitle,
                                     iconString: toggleActionIcon) { _, _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
            }
        }
    }

    private func getCopyAction() -> PhotonActionSheetItem? {

        return PhotonActionSheetItem(title: .AppMenuCopyLinkTitleString,
                                     iconString: "menu-Copy-Link") { _, _ in

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
            if let url = self.selectedTab?.canonicalURL?.displayURL {
                UIPasteboard.general.url = url
                self.delegate?.showToast(message: .AppMenuCopyURLConfirmMessage, toastAction: .copyUrl, url: nil)
            }
        }
    }

    private func getSendToDevice() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .SendLinkToDeviceTitle,
                                     iconString: "menu-Send-to-Device") { _, _ in
            guard let bvc = self.menuActionDelegate as? InstructionsViewControllerDelegate & DevicePickerViewControllerDelegate else { return }

            if !self.profile.hasAccount() {
                let instructionsViewController = InstructionsViewController()
                instructionsViewController.delegate = bvc
                let navigationController = UINavigationController(rootViewController: instructionsViewController)
                navigationController.modalPresentationStyle = .formSheet
                self.delegate?.showViewController(viewController: navigationController)
                return
            }

            let devicePickerViewController = DevicePickerViewController()
            devicePickerViewController.pickerDelegate = bvc
            devicePickerViewController.profile = self.profile
            devicePickerViewController.profileNeedsShutdown = false
            let navigationController = UINavigationController(rootViewController: devicePickerViewController)
            navigationController.modalPresentationStyle = .formSheet
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
            self.delegate?.showViewController(viewController: navigationController)
        }
    }

    private func getReportSiteIssueAction() -> PhotonActionSheetItem? {
        guard featureFlags.isFeatureActiveForBuild(.reportSiteIssue) else { return nil }
        return PhotonActionSheetItem(title: .AppMenuReportSiteIssueTitleString,
                                     iconString: "menu-reportSiteIssue") { _, _ in
            guard let tabURL = self.tabManager.selectedTab?.url?.absoluteString else { return }
            self.delegate?.openURLInNewTab(SupportUtils.URLForReportSiteIssue(tabURL), isPrivate: false)
        }
    }

    private func getHelpAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppSettingsHelp,
                                     iconString: "help") { _, _ in

            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }
        }
    }

    private func getCustomizeHomePageAction() -> PhotonActionSheetItem? {
        return PhotonActionSheetItem(title: .FirefoxHomepage.CustomizeHomepage.ButtonTitle,
                                     iconString: "edit") { _, _ in
            self.delegate?.showCustomizeHomePage()
        }
    }

    // MARK: Whats New

    private func getWhatsNewAction() -> PhotonActionSheetItem? {
        var whatsNewAction: PhotonActionSheetItem?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Redraw the toolbar so the badge hides from the appMenu button.
            delegate?.updateToolbarState()
        }

        whatsNewAction = PhotonActionSheetItem(title: .WhatsNewString, iconString: "whatsnew", isEnabled: showBadgeForWhatsNew) { _, _ in
            if let whatsNewTopic = AppInfo.whatsNewTopic, let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .whatsNew)
                self.delegate?.openURLInNewTab(whatsNewURL, isPrivate: false)
            }
        }
        return whatsNewAction
    }

    // If we do not have the LatestAppVersionProfileKey in the profile, that means that this is a fresh install and we
    // do not show the What's New. If we do have that value, we compare it to the major version of the running app.
    // If it is different then this is an upgrade, downgrades are not possible, so we can show the What's New page.
    private func shouldShowWhatsNew() -> Bool {
        guard let latestMajorAppVersion = profile.prefs.stringForKey(LatestAppVersionProfileKey)?.components(separatedBy: ".").first else {
            return false // Clean install, never show What's New
        }

        return latestMajorAppVersion != AppInfo.majorAppVersion && DeviceInfo.hasConnectivity()
    }

    // MARK: Share

    private func getShareFileAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuSharePageTitleString,
                                     iconString: "action_share") { _, _ in

            guard let tab = self.selectedTab,
                    let url = tab.canonicalURL?.displayURL,
                    let presentableVC = self.menuActionDelegate as? PresentableVC else { return }

            self.share(fileURL: url, buttonView: self.buttonView, presentableVC: presentableVC)
        }
    }

    private func getShareAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .ShareContextMenuTitle,
                                     iconString: "action_share") { _, _ in

            guard let tab = self.selectedTab, let url = tab.canonicalURL?.displayURL else { return }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
            if let temporaryDocument = tab.temporaryDocument {
                temporaryDocument.getURL().uponQueue(.main, block: { tempDocURL in
                    // If we successfully got a temp file URL, share it like a downloaded file,
                    // otherwise present the ordinary share menu for the web URL.
                    if tempDocURL.isFileURL, let presentableVC = self.menuActionDelegate as? PresentableVC {
                        self.share(fileURL: tempDocURL, buttonView: self.buttonView, presentableVC: presentableVC)
                    } else {
                        self.delegate?.showMenuPresenter(url: url, tab: tab, view: self.buttonView)
                    }
                })
            } else {
                self.delegate?.showMenuPresenter(url: url, tab: tab, view: self.buttonView)
            }
        }
    }

    private func share(fileURL: URL, buttonView: UIView, presentableVC: PresentableVC) {
        let helper = ShareExtensionHelper(url: fileURL, tab: tabManager.selectedTab)
        let controller = helper.createActivityViewController { completed, activityType in
            print("Shared downloaded file: \(completed)")
        }

        if let popoverPresentationController = controller.popoverPresentationController {
            popoverPresentationController.sourceView = buttonView
            popoverPresentationController.sourceRect = buttonView.bounds
            popoverPresentationController.permittedArrowDirections = .up
        }
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
        presentableVC.present(controller, animated: true, completion: nil)
    }

    // MARK: Reading list

    private func getReadingListSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        let libraryAction = getReadingListLibraryAction()
        section.append(libraryAction)

        if !isHomePage {
            let readingListAction = getAddReadingListAction()
            section.append(readingListAction)
        }

        return section
    }

    private func getReadingListLibraryAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuReadingList,
                                                iconString: "menu-panel-ReadingList") { _, _ in
            self.delegate?.showLibrary(panel: .readingList)
        }
    }

    private func getAddReadingListAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuAddToReadingListTitleString,
                                     iconString: "addToReadingList") { _, _ in

            guard let tab = self.selectedTab,
                  let url = self.tabUrl?.displayURL else { return }

            self.profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .readingListItem, value: .pageActionMenu)
            self.delegate?.showToast(message: .AppMenuAddToReadingListConfirmMessage, toastAction: .addToReadingList, url: nil)
        }
    }

    // MARK: Bookmark

    private func getBookmarkSection() -> [PhotonActionSheetItem] {
        var section = [PhotonActionSheetItem]()

        let libraryAction = getBookmarkLibraryAction()
        section.append(libraryAction)

        if !isHomePage {
            let bookmarkAction = getBookmarkAction()
            section.append(bookmarkAction)
        }

        return section
    }

    private func getBookmarkLibraryAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuBookmarks,
                                     iconString: "menu-panel-Bookmarks") { _, _ in
            self.delegate?.showLibrary(panel: .bookmarks)
        }
    }

    private func getBookmarkAction() -> PhotonActionSheetItem {
        let addBookmarkAction = getAddBookmarkAction()
        let removeBookmarkAction = getRemoveBookmarkAction()

        let isBookmarked = isBookmarked ?? false
        return isBookmarked ? removeBookmarkAction : addBookmarkAction
    }

    private func getAddBookmarkAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuAddBookmarkTitleString2,
                                     iconString: "menu-Bookmark") { _, _ in

            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL else { return }

            self.delegate?.addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .pageActionMenu)
        }
    }

    private func getRemoveBookmarkAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuRemoveBookmarkTitleString,
                                     iconString: "menu-Bookmark-Remove") { _, _ in

            guard let url = self.tabUrl?.displayURL else { return }

            self.profile.places.deleteBookmarksWithURL(url: url.absoluteString).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(message: .AppMenuRemoveBookmarkConfirmMessage, toastAction: .removeBookmark, url: url.absoluteString)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .pageActionMenu)
        }
    }

    // MARK: Shortcut

    private func getShortcutAction() -> PhotonActionSheetItem {
        let addShortcutAction = getAddShortcutAction()
        let removeShortcutAction = getRemoveShortcutAction()

        let isPinned = isPinned ?? false
        return isPinned ? removeShortcutAction : addShortcutAction
    }

    private func getAddShortcutAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AddToShortcutsActionTitle,
                                     iconString: "action_pin") { _, _ in

            guard let url = self.tabManager.selectedTab?.url?.displayURL,
                  let sql = self.profile.history as? SQLiteHistory else { return }

            sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }
                return self.profile.history.addPinnedTopSite(site)

            }.uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(message: .AppMenuAddPinToShortcutsConfirmMessage, toastAction: .pinPage, url: nil)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pinToTopSites)
        }
    }

    private func getRemoveShortcutAction() -> PhotonActionSheetItem {
        return PhotonActionSheetItem(title: .AppMenuRemoveBookmarkTitleString,
                                     iconString: "menu-Bookmark-Remove") { _, _ in

            guard let url = self.tabManager.selectedTab?.url?.absoluteString else { return }

            self.profile.places.deleteBookmarksWithURL(url: url).uponQueue(.main) { result in
                if result.isSuccess {
                    self.delegate?.showToast(message: .AppMenuRemoveBookmarkConfirmMessage, toastAction: .removeBookmark, url: url)
                }
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .pageActionMenu)
        }
    }

    // MARK: Password

    typealias NavigationHandlerType = ((_ url: URL?) -> Void)
    private func getPasswordAction(navigationController: UINavigationController?) -> PhotonActionSheetItem? {
        let isLoginsButtonShowing = LoginListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs)
        guard isLoginsButtonShowing else { return nil }

        return PhotonActionSheetItem(title: .AppMenuPasswords,
                                     iconString: "key",
                                     iconType: .Image,
                                     iconAlignment: .left) { _, _ in

            guard let navigationController = navigationController else { return }
            let navigationHandler: NavigationHandlerType = { url in
                UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }

            if AppAuthenticator.canAuthenticateDeviceOwner() {
                if LoginOnboarding.shouldShow() {
                    self.showLoginOnboarding(navigationHandler: navigationHandler, navigationController: navigationController)
                } else {
                    self.showLoginListVC(navigationHandler: navigationHandler, navigationController: navigationController)
                }

            } else {
                let rootViewController = DevicePasscodeRequiredViewController(shownFromAppMenu: true)
                let navController = ThemedNavigationController(rootViewController: rootViewController)
                self.delegate?.showViewController(viewController: navController)
            }
        }
    }

    private func showLoginOnboarding(navigationHandler: @escaping NavigationHandlerType, navigationController: UINavigationController) {
        let loginOnboardingViewController = LoginOnboardingViewController(shownFromAppMenu: true)
        loginOnboardingViewController.doneHandler = {
            loginOnboardingViewController.dismiss(animated: true)
        }

        loginOnboardingViewController.proceedHandler = {
            loginOnboardingViewController.dismiss(animated: true) {
                self.showLoginListVC(navigationHandler: navigationHandler, navigationController: navigationController)
            }
        }

        let navController = ThemedNavigationController(rootViewController: loginOnboardingViewController)
        delegate?.showViewController(viewController: navController)

        LoginOnboarding.setShown()
    }

    private func showLoginListVC(navigationHandler: @escaping NavigationHandlerType, navigationController: UINavigationController) {
        guard let menuActionDelegate = menuActionDelegate else { return }
        LoginListViewController.create(authenticateInNavigationController: navigationController,
                                       profile: self.profile,
                                       settingsDelegate: menuActionDelegate,
                                       webpageNavigationHandler: navigationHandler).uponQueue(.main) { loginsVC in
            self.presentLoginList(loginsVC)
        }
    }

    private func presentLoginList(_ loginsVC: LoginListViewController?) {
        guard let loginsVC = loginsVC else { return }
        loginsVC.shownFromAppMenu = true
        let navController = ThemedNavigationController(rootViewController: loginsVC)
        delegate?.showViewController(viewController: navController)

        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .logins)
    }

    // MARK: - Conveniance

    private func append(to items: inout [PhotonActionSheetItem], action: PhotonActionSheetItem?) {
        if let action = action {
            items.append(action)
        }
    }

    private func append(to items: inout [PhotonActionSheetItem], action: [PhotonActionSheetItem]?) {
        if let action = action {
            items.append(contentsOf: action)
        }
    }
}
