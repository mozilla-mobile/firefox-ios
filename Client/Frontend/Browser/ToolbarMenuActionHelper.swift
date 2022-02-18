// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared
import Storage
import UIKit

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

typealias FXASyncClosure = (params: FxALaunchParams?, flowType: FxAPageType, referringPage: ReferringPage)

/// ToolbarMenuActionHelper handles the hamburger menu in the toolbar.
/// There is three different types of hamburger menu:
///     - The home page menu, determined with isHomePage variable
///     - The file URL menu, shown when the user is on a url of type `file://`
///     - The site menu, determined by the absence of isHomePage and isFileURL
class ToolbarMenuActionHelper: PhotonActionSheetProtocol, FeatureFlagsProtocol {

    private let isHomePage: Bool
    private let buttonView: UIButton
    private let selectedTab: Tab?
    private let tabUrl: URL?
    private let isFileURL: Bool
    private let showFXASyncAction: (FXASyncClosure) -> Void

    let profile: Profile
    let tabManager: TabManager

    weak var delegate: ToolBarActionMenuDelegate?
    weak var menuActionDelegate: MenuActionsDelegate?

    /// ToolbarMenuActionHelper init
    /// - Parameters:
    ///   - profile: the user's profile
    ///   - tabManager: the tab manager
    ///   - buttonView: the view from which the menu will be shown
    ///   - showFXASyncAction: the closure that will be executed for the sync action in the library section
    init(profile: Profile,
         tabManager: TabManager,
         buttonView: UIButton,
         showFXASyncAction: @escaping (FXASyncClosure) -> Void) {

        self.profile = profile
        self.tabManager = tabManager
        self.buttonView = buttonView
        self.showFXASyncAction = showFXASyncAction

        self.selectedTab = tabManager.selectedTab
        self.tabUrl = selectedTab?.url
        self.isFileURL = tabUrl?.isFileURL ?? false
        self.isHomePage = selectedTab?.isFxHomeTab ?? false
    }

    func getToolbarActions(navigationController: UINavigationController?,
                           completion: @escaping ([[PhotonRowItems]]) -> Void) {
        var actions: [[PhotonRowItems]] = []
        let firstMiscSection = getFirstMiscSection(navigationController)

        if isHomePage {
            actions.append(contentsOf: [
                getLibrarySection(),
                firstMiscSection,
                getLastSection()
            ])

            completion(actions)

        } else {

            // Actions on site page need specific data to be loaded
            updateData(dataLoadingCompletion: {
                actions.append(contentsOf: [
                    self.getNewTabSection(),
                    self.getLibrarySection(),
                    firstMiscSection,
                    self.getSecondMiscSection(),
                    self.getLastSection()
                ])

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

    private func getNewTabSection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()
        append(to: &section, action: getNewTabAction())

        return section
    }

    private func getLibrarySection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

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

        let syncAction = syncMenuButton(showFxA: showFXASyncAction)
        append(to: &section, action: syncAction)

        return section
    }

    private func getFirstMiscSection(_ navigationController: UINavigationController?) -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

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

    private func getSecondMiscSection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

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

    private func getLastSection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

        if isHomePage {
            let whatsNewAction = getWhatsNewAction()
            append(to: &section, action: whatsNewAction)

            let helpAction = getHelpAction()
            section.append(helpAction)

            let customizeHomePageAction = getCustomizeHomePageAction()
            append(to: &section, action: customizeHomePageAction)
        }

        let settingsAction = getSettingsAction()
        section.append(settingsAction)

        return section
    }

    // MARK: - Actions

    private func getNewTabAction() -> PhotonRowItems {
        return SingleSheetItem(title: .KeyboardShortcuts.NewTab,
                               iconString: "quick_action_new_tab") { _, _ in

            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.delegate?.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false, searchFor: nil)
        }.items
    }

    private func getHistoryLibraryAction() -> PhotonRowItems {
        return SingleSheetItem(title: .AppMenuHistory,
                               iconString: "menu-panel-History") { _, _ in
            self.delegate?.showLibrary(panel: .history)
        }.items
    }

    private func getDownloadsLibraryAction() -> PhotonRowItems {
        return SingleSheetItem(title: .AppMenuDownloads,
                               iconString: "menu-panel-Downloads") { _, _ in
            self.delegate?.showLibrary(panel: .downloads)
        }.items
    }

    private func getFindInPageAction() -> PhotonRowItems {
        return SingleSheetItem(title: .AppMenuFindInPageTitleString,
                               iconString: "menu-FindInPage") { _, _ in
            self.delegate?.showFindInPage()
        }.items
    }

    private func getRequestDesktopSiteAction() -> PhotonRowItems? {
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

        return SingleSheetItem(title: toggleActionTitle,
                               iconString: toggleActionIcon) { _, _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
            }
        }.items
    }

    private func getCopyAction() -> PhotonRowItems? {

        return SingleSheetItem(title: .AppMenuCopyLinkTitleString,
                               iconString: "menu-Copy-Link") { _, _ in

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
            if let url = self.selectedTab?.canonicalURL?.displayURL {
                UIPasteboard.general.url = url
                self.delegate?.showToast(message: .AppMenuCopyURLConfirmMessage, toastAction: .copyUrl, url: nil)
            }
        }.items
    }

    private func getSendToDevice() -> PhotonRowItems {
        return SingleSheetItem(title: .SendLinkToDeviceTitle,
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
        }.items
    }

    private func getReportSiteIssueAction() -> PhotonRowItems? {
        guard featureFlags.isFeatureActiveForBuild(.reportSiteIssue) else { return nil }
        return SingleSheetItem(title: .AppMenuReportSiteIssueTitleString,
                               iconString: "menu-reportSiteIssue") { _, _ in
            guard let tabURL = self.selectedTab?.url?.absoluteString else { return }
            self.delegate?.openURLInNewTab(SupportUtils.URLForReportSiteIssue(tabURL), isPrivate: false)
        }.items
    }

    private func getHelpAction() -> PhotonRowItems {
        return SingleSheetItem(title: .AppSettingsHelp,
                               iconString: "help") { _, _ in

            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }
        }.items
    }

    private func getCustomizeHomePageAction() -> PhotonRowItems? {
        return SingleSheetItem(title: .FirefoxHomepage.CustomizeHomepage.ButtonTitle,
                               iconString: "edit") { _, _ in
            self.delegate?.showCustomizeHomePage()
        }.items
    }

    private func getSettingsAction() -> PhotonRowItems {
        // This method is being called when we the user sees the menu, not just when it's constructed.
        // In that case, we can let sendExposureEvent default to true.
        let variables = Experiments.shared.getVariables(featureId: .nimbusValidation)
        // Get the title and icon for this feature from nimbus.
        // We need to provide defaults if Nimbus doesn't provide them.
        let title = variables.getText("settings-title") ?? .AppMenuSettingsTitleString
        let icon = variables.getString("settings-icon") ?? "menu-Settings"

        let openSettings = SingleSheetItem(title: title,
                                           iconString: icon) { _, _ in
            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = self.menuActionDelegate

            let controller = ThemedNavigationController(rootViewController: settingsTableViewController)
            // On iPhone iOS13 the WKWebview crashes while presenting file picker if its not full screen. Ref #6232
            if UIDevice.current.userInterfaceIdiom == .phone {
                controller.modalPresentationStyle = .fullScreen
            }
            controller.presentingModalViewControllerDelegate = self.menuActionDelegate
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .settings)

            // Wait to present VC in an async dispatch queue to prevent a case where dismissal
            // of this popover on iPad seems to block the presentation of the modal VC.
            DispatchQueue.main.async {
                self.delegate?.showViewController(viewController: controller)
            }
        }.items
        return openSettings
    }

    private func getNightModeAction() -> [PhotonRowItems] {
        var items: [PhotonRowItems] = []

        let nightModeEnabled = NightModeHelper.isActivated(profile.prefs)
        let nightModeTitle: String = nightModeEnabled ? .AppMenuTurnOffNightMode : .AppMenuTurnOnNightMode
        let nightMode = SingleSheetItem(title: nightModeTitle,
                                        iconString: "menu-NightMode",
                                        isEnabled: nightModeEnabled) { _, _ in
            NightModeHelper.toggle(self.profile.prefs, tabManager: self.tabManager)

            if nightModeEnabled {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeEnabled)
            } else {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeDisabled)
            }

            // If we've enabled night mode and the theme is normal, enable dark theme
            if NightModeHelper.isActivated(self.profile.prefs), LegacyThemeManager.instance.currentName == .normal {
                LegacyThemeManager.instance.current = DarkTheme()
                NightModeHelper.setEnabledDarkTheme(self.profile.prefs, darkTheme: true)
            }

            // If we've disabled night mode and dark theme was activated by it then disable dark theme
            if !NightModeHelper.isActivated(self.profile.prefs), NightModeHelper.hasEnabledDarkTheme(self.profile.prefs), LegacyThemeManager.instance.currentName == .dark {
                LegacyThemeManager.instance.current = NormalTheme()
                NightModeHelper.setEnabledDarkTheme(self.profile.prefs, darkTheme: false)
            }
        }.items
        items.append(nightMode)

        return items
    }

    private func syncMenuButton(showFxA: @escaping (FXASyncClosure) -> Void) -> PhotonRowItems? {
        let action: ((SingleSheetItem, UITableViewCell) -> Void) = { action, _ in
            let fxaParams = FxALaunchParams(query: ["entrypoint": "browsermenu"])
            let params = FXASyncClosure(fxaParams, .emailLoginFlow, .appMenu)
            showFxA(params)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
        }

        let rustAccount = RustFirefoxAccounts.shared
        let needsReAuth = rustAccount.accountNeedsReauth()

        guard let userProfile = rustAccount.userProfile else {
            return SingleSheetItem(title: .AppMenuBackUpAndSyncData,
                                   iconString: "menu-sync",
                                   handler: action).items
        }

        let title: String = {
            if rustAccount.accountNeedsReauth() {
                return .FxAAccountVerifyPassword
            }
            return userProfile.displayName ?? userProfile.email
        }()

        let iconString = needsReAuth ? "menu-warning" : "placeholder-avatar"

        var iconURL: URL? = nil
        if let str = rustAccount.userProfile?.avatarUrl, let url = URL(string: str) {
            iconURL = url
        }
        let iconType: PhotonActionSheetIconType = needsReAuth ? .Image : .URL
        let iconTint: UIColor? = needsReAuth ? UIColor.Photon.Yellow60 : nil
        let syncOption = SingleSheetItem(title: title, iconString: iconString, iconURL: iconURL,
                                         iconType: iconType, iconTint: iconTint, handler: action).items
        return syncOption
    }

    // MARK: Whats New

    private func getWhatsNewAction() -> PhotonRowItems? {
        var whatsNewAction: PhotonRowItems?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Redraw the toolbar so the badge hides from the appMenu button.
            delegate?.updateToolbarState()
        }

        whatsNewAction = SingleSheetItem(title: .WhatsNewString,
                                         iconString: "whatsnew",
                                         isEnabled: showBadgeForWhatsNew) { _, _ in
            if let whatsNewTopic = AppInfo.whatsNewTopic, let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .whatsNew)
                self.delegate?.openURLInNewTab(whatsNewURL, isPrivate: false)
            }
        }.items
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

    private func getShareFileAction() -> PhotonRowItems {
        return SingleSheetItem(title: .AppMenuSharePageTitleString,
                               iconString: "action_share") { _, _ in

            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL,
                  let presentableVC = self.menuActionDelegate as? PresentableVC else { return }

            self.share(fileURL: url, buttonView: self.buttonView, presentableVC: presentableVC)
        }.items
    }

    private func getShareAction() -> PhotonRowItems {
        return SingleSheetItem(title: .ShareContextMenuTitle,
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
        }.items
    }

    private func share(fileURL: URL, buttonView: UIView, presentableVC: PresentableVC) {
        let helper = ShareExtensionHelper(url: fileURL, tab: selectedTab)
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

    private func getReadingListSection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

        let libraryAction = getReadingListLibraryAction()
        if !isHomePage {
            let readingListAction = getAddReadingListAction()
            section.append(PhotonRowItems([libraryAction, readingListAction]))
        } else {
            section.append(PhotonRowItems(libraryAction))
        }

        return section
    }

    private func getReadingListLibraryAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuReadingList,
                               iconString: "menu-panel-ReadingList") { _, _ in
            self.delegate?.showLibrary(panel: .readingList)
        }
    }

    private func getAddReadingListAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuAddToReadingListTitleString,
                               iconString: "addToReadingList") { _, _ in

            guard let tab = self.selectedTab,
                  let url = self.tabUrl?.displayURL else { return }

            self.profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .readingListItem, value: .pageActionMenu)
            self.delegate?.showToast(message: .AppMenuAddToReadingListConfirmMessage, toastAction: .addToReadingList, url: nil)
        }
    }

    // MARK: Bookmark

    private func getBookmarkSection() -> [PhotonRowItems] {
        var section = [PhotonRowItems]()

        let libraryAction = getBookmarkLibraryAction()
        if !isHomePage {
            let bookmarkAction = getBookmarkAction()
            section.append(PhotonRowItems([libraryAction, bookmarkAction]))
        } else {
            section.append(PhotonRowItems(libraryAction))
        }

        return section
    }

    private func getBookmarkLibraryAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuBookmarks,
                               iconString: "menu-panel-Bookmarks") { _, _ in
            self.delegate?.showLibrary(panel: .bookmarks)
        }
    }

    private func getBookmarkAction() -> SingleSheetItem {
        let addBookmarkAction = getAddBookmarkAction()
        let removeBookmarkAction = getRemoveBookmarkAction()

        let isBookmarked = isBookmarked ?? false
        return isBookmarked ? removeBookmarkAction : addBookmarkAction
    }

    private func getAddBookmarkAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuAddBookmarkTitleString2,
                               iconString: "menu-Bookmark") { _, _ in

            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL else { return }

            self.delegate?.addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .pageActionMenu)
        }
    }

    private func getRemoveBookmarkAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuRemoveBookmarkTitleString,
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

    private func getShortcutAction() -> PhotonRowItems {
        let addShortcutAction = getAddShortcutAction()
        let removeShortcutAction = getRemoveShortcutAction()

        let isPinned = isPinned ?? false
        return isPinned ? removeShortcutAction.items : addShortcutAction.items
    }

    private func getAddShortcutAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AddToShortcutsActionTitle,
                               iconString: "action_pin") { _, _ in

            guard let url = self.selectedTab?.url?.displayURL,
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

    private func getRemoveShortcutAction() -> SingleSheetItem {
        return SingleSheetItem(title: .AppMenuRemoveBookmarkTitleString,
                               iconString: "menu-Bookmark-Remove") { _, _ in

            guard let url = self.selectedTab?.url?.absoluteString else { return }

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
    private func getPasswordAction(navigationController: UINavigationController?) -> PhotonRowItems? {
        let isLoginsButtonShowing = LoginListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs)
        guard isLoginsButtonShowing else { return nil }

        return SingleSheetItem(title: .AppMenuPasswords,
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
        }.items
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

    private func append(to items: inout [PhotonRowItems], action: PhotonRowItems?) {
        if let action = action {
            items.append(action)
        }
    }

    private func append(to items: inout [PhotonRowItems], action: [PhotonRowItems]?) {
        if let action = action {
            items.append(contentsOf: action)
        }
    }
}
