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
    case removeFromReadingList
    case bookmarkPage
    case removeBookmark
    case copyUrl
    case pinPage
    case removePinPage
}

/// MainMenuActionHelper handles the main menu (hamburger menu) in the toolbar.
/// There is three different types of main menu:
///     - The home page menu, determined with isHomePage variable
///     - The file URL menu, shown when the user is on a url of type `file://`
///     - The site menu, determined by the absence of isHomePage and isFileURL
class MainMenuActionHelper: PhotonActionSheetProtocol, FeatureFlaggable, CanRemoveQuickActionBookmark {

    typealias FXASyncClosure = (params: FxALaunchParams?, flowType: FxAPageType, referringPage: ReferringPage)

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

    /// MainMenuActionHelper init
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
                           completion: @escaping ([[PhotonRowActions]]) -> Void) {
        var actions: [[PhotonRowActions]] = []
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

    private let dataQueue = DispatchQueue(label: "com.moz.mainMenuAction.queue")
    private var isInReadingList = false
    private var isBookmarked = false
    private var isPinned = false

    /// Update data to show the proper menus related to the page
    /// - Parameter dataLoadingCompletion: Complete when the loading of data from the profile is done
    private func updateData(dataLoadingCompletion: (() -> Void)? = nil) {
        guard let url = tabUrl?.absoluteString else {
            dataLoadingCompletion?()
            return
        }

        let group = DispatchGroup()
        getIsBookmarked(url: url, group: group)
        getIsPinned(url: url, group: group)
        getIsInReadingList(url: url, group: group)

        let dataQueue = DispatchQueue.global(qos: .userInitiated)
        group.notify(queue: dataQueue) {
            dataLoadingCompletion?()
        }
    }

    private func getIsInReadingList(url: String, group: DispatchGroup) {
        group.enter()
        profile.readingList.getRecordWithURL(url).uponQueue(dataQueue) { result in
            self.isInReadingList = result.successValue != nil
            group.leave()
        }
    }

    private func getIsBookmarked(url: String, group: DispatchGroup) {
        group.enter()
        profile.places.isBookmarked(url: url).uponQueue(dataQueue) { result in
            self.isBookmarked = result.successValue ?? false
            group.leave()
        }
    }

    private func getIsPinned(url: String, group: DispatchGroup) {
        group.enter()
        profile.history.isPinnedTopSite(url).uponQueue(dataQueue) { result in
            self.isPinned = result.successValue ?? false
            group.leave()
        }
    }

    // MARK: - Sections

    private func getNewTabSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()
        append(to: &section, action: getNewTabAction())

        return section
    }

    private func getLibrarySection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

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

    private func getFirstMiscSection(_ navigationController: UINavigationController?) -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

        if !isHomePage && !isFileURL {
            let findInPageAction = getFindInPageAction()
            append(to: &section, action: findInPageAction)

            let desktopSiteAction = getRequestDesktopSiteAction()
            append(to: &section, action: desktopSiteAction)
        }

        let nightModeAction = getNightModeAction()
        append(to: &section, action: nightModeAction)

        let passwordsAction = getPasswordAction(navigationController: navigationController)
        append(to: &section, action: passwordsAction)

        if !isHomePage && !isFileURL {
            let reportSiteIssueAction = getReportSiteIssueAction()
            append(to: &section, action: reportSiteIssueAction)
        }

        return section
    }

    private func getSecondMiscSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

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

    private func getLastSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

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

    private func getNewTabAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.NewTab,
                                     iconString: ImageIdentifiers.newTab) { _ in

            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) == .blankPage
            self.delegate?.openBlankNewTab(focusLocationField: shouldFocusLocationField, isPrivate: false, searchFor: nil)
        }.items
    }

    private func getHistoryLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuHistory,
                                     iconString: ImageIdentifiers.history) { _ in
            self.delegate?.showLibrary(panel: .history)
        }.items
    }

    private func getDownloadsLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuDownloads,
                                     iconString: ImageIdentifiers.downloads) { _ in
            self.delegate?.showLibrary(panel: .downloads)
        }.items
    }

    private func getFindInPageAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuFindInPageTitleString,
                                     iconString: ImageIdentifiers.findInPage) { _ in
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .findInPage)
            self.delegate?.showFindInPage()
        }.items
    }

    private func getRequestDesktopSiteAction() -> PhotonRowActions? {
        guard let tab = selectedTab else { return nil }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        let toggleActionIcon: String
        let siteTypeTelemetryObject: TelemetryWrapper.EventObject
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.AppMenuViewDesktopSiteTitleString : .AppMenu.AppMenuViewMobileSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? ImageIdentifiers.requestDesktopSite : ImageIdentifiers.requestMobileSite
            siteTypeTelemetryObject = .requestDesktopSite

        } else {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.AppMenuViewMobileSiteTitleString : .AppMenu.AppMenuViewDesktopSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? ImageIdentifiers.requestMobileSite : ImageIdentifiers.requestDesktopSite
            siteTypeTelemetryObject = .requestMobileSite
        }

        return SingleActionViewModel(title: toggleActionTitle,
                                     iconString: toggleActionIcon) { _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
            }
        }.items
    }

    private func getCopyAction() -> PhotonRowActions? {
        return SingleActionViewModel(title: .AppMenu.AppMenuCopyLinkTitleString,
                                     iconString: ImageIdentifiers.copyLink) { _ in

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
            if let url = self.selectedTab?.canonicalURL?.displayURL {
                UIPasteboard.general.url = url
                self.delegate?.showToast(message: .AppMenu.AppMenuCopyURLConfirmMessage, toastAction: .copyUrl, url: nil)
            }
        }.items
    }

    private func getSendToDevice() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.TouchActions.SendLinkToDeviceTitle,
                                     iconString: ImageIdentifiers.sendToDevice) { _ in
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

    private func getReportSiteIssueAction() -> PhotonRowActions? {
        guard featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly) else { return nil }

        return SingleActionViewModel(title: .AppMenu.AppMenuReportSiteIssueTitleString,
                                     iconString: ImageIdentifiers.reportSiteIssue) { _ in
            guard let tabURL = self.selectedTab?.url?.absoluteString else { return }
            self.delegate?.openURLInNewTab(SupportUtils.URLForReportSiteIssue(tabURL), isPrivate: false)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .reportSiteIssue)
        }.items
    }

    private func getHelpAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.Help,
                                     iconString: ImageIdentifiers.help) { _ in

            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.openURLInNewTab(url, isPrivate: false)
            }
        }.items
    }

    private func getCustomizeHomePageAction() -> PhotonRowActions? {
        return SingleActionViewModel(title: .AppMenu.CustomizeHomePage,
                                     iconString: ImageIdentifiers.edit) { _ in
            self.delegate?.showCustomizeHomePage()
        }.items
    }

    private func getSettingsAction() -> PhotonRowActions {
        let title = String.AppMenu.AppMenuSettingsTitleString
        let icon = ImageIdentifiers.settings

        let openSettings = SingleActionViewModel(title: title,
                                                 iconString: icon) { _ in
            let settingsTableViewController = AppSettingsTableViewController(
                with: self.profile,
                and: self.tabManager,
                delegate: self.menuActionDelegate)

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

    private func getNightModeAction() -> [PhotonRowActions] {
        var items: [PhotonRowActions] = []

        let nightModeEnabled = NightModeHelper.isActivated(profile.prefs)
        let nightModeTitle: String = nightModeEnabled ? .AppMenu.AppMenuTurnOffNightMode : .AppMenu.AppMenuTurnOnNightMode
        let nightMode = SingleActionViewModel(title: nightModeTitle,
                                              iconString: ImageIdentifiers.nightMode,
                                              isEnabled: nightModeEnabled) { _ in
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

    private func syncMenuButton(showFxA: @escaping (FXASyncClosure) -> Void) -> PhotonRowActions? {
        let action: ((SingleActionViewModel) -> Void) = { action in
            let fxaParams = FxALaunchParams(query: ["entrypoint": "browsermenu"])
            let params = FXASyncClosure(fxaParams, .emailLoginFlow, .appMenu)
            showFxA(params)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
        }

        let rustAccount = RustFirefoxAccounts.shared
        let needsReAuth = rustAccount.accountNeedsReauth()

        guard let userProfile = rustAccount.userProfile else {
            return SingleActionViewModel(title: .AppMenu.AppMenuBackUpAndSyncData,
                                         iconString: ImageIdentifiers.sync,
                                         tapHandler: action).items
        }

        let title: String = {
            if rustAccount.accountNeedsReauth() {
                return .FxAAccountVerifyPassword
            }
            return userProfile.displayName ?? userProfile.email
        }()

        let iconString = needsReAuth ? ImageIdentifiers.warning : ImageIdentifiers.placeholderAvatar

        var iconURL: URL?
        if let str = rustAccount.userProfile?.avatarUrl, let url = URL(string: str) {
            iconURL = url
        }
        let iconType: PhotonActionSheetIconType = needsReAuth ? .Image : .URL
        let iconTint: UIColor? = needsReAuth ? UIColor.Photon.Yellow60 : nil
        let syncOption = SingleActionViewModel(title: title,
                                               iconString: iconString,
                                               iconURL: iconURL,
                                               iconType: iconType,
                                               iconTint: iconTint,
                                               tapHandler: action).items
        return syncOption
    }

    // MARK: Whats New

    private func getWhatsNewAction() -> PhotonRowActions? {
        var whatsNewAction: PhotonRowActions?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)

            // Redraw the toolbar so the badge hides from the appMenu button.
            delegate?.updateToolbarState()
        }

        whatsNewAction = SingleActionViewModel(title: .AppMenu.WhatsNewString,
                                               iconString: ImageIdentifiers.whatsNew,
                                               isEnabled: showBadgeForWhatsNew) { _ in
            if let whatsNewTopic = AppInfo.whatsNewTopic,
                let whatsNewURL = SupportUtils.URLForTopic(whatsNewTopic) {
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

    private func getShareFileAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuSharePageTitleString,
                                     iconString: ImageIdentifiers.share) { _ in

            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL,
                  let presentableVC = self.menuActionDelegate as? PresentableVC
            else { return }

            self.share(fileURL: url, buttonView: self.buttonView, presentableVC: presentableVC)
        }.items
    }

    private func getShareAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.Share,
                                     iconString: ImageIdentifiers.share) { _ in

            guard let tab = self.selectedTab, let url = tab.canonicalURL?.displayURL else { return }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
            if let temporaryDocument = tab.temporaryDocument {
                temporaryDocument.getURL().uponQueue(.main, block: { tempDocURL in
                    // If we successfully got a temp file URL, share it like a downloaded file,
                    // otherwise present the ordinary share menu for the web URL.
                    if tempDocURL.isFileURL,
                        let presentableVC = self.menuActionDelegate as? PresentableVC {
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
        delegate?.showViewController(viewController: controller)
    }

    // MARK: Reading list

    private func getReadingListSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

        let libraryAction = getReadingListLibraryAction()
        if !isHomePage {
            let readingListAction = getReadingListAction()
            section.append(PhotonRowActions([libraryAction, readingListAction]))
        } else {
            section.append(PhotonRowActions(libraryAction))
        }

        return section
    }

    private func getReadingListLibraryAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.ReadingList,
                                     iconString: ImageIdentifiers.readingList) { _ in
            self.delegate?.showLibrary(panel: .readingList)
        }
    }

    private func getReadingListAction() -> SingleActionViewModel {
        return isInReadingList ? getRemoveReadingListAction() : getAddReadingListAction()
    }

    private func getAddReadingListAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.AddReadingList,
                                     alternateTitle: .AppMenu.AddReadingListAlternateTitle,
                                     iconString: ImageIdentifiers.addToReadingList) { _ in

            guard let tab = self.selectedTab,
                  let url = self.tabUrl?.displayURL
            else { return }

            self.profile.readingList.createRecordWithURL(url.absoluteString, title: tab.title ?? "", addedBy: UIDevice.current.name)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .readingListItem, value: .pageActionMenu)
            self.delegate?.showToast(message: .AppMenu.AddToReadingListConfirmMessage, toastAction: .addToReadingList, url: nil)
        }
    }

    private func getRemoveReadingListAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.RemoveReadingList,
                                     alternateTitle: .AppMenu.RemoveReadingListAlternateTitle,
                                     iconString: ImageIdentifiers.removeFromReadingList) { _ in

            guard let url = self.tabUrl?.displayURL?.absoluteString,
                  let record = self.profile.readingList.getRecordWithURL(url).value.successValue
            else { return }

            self.profile.readingList.deleteRecord(record)
            self.delegate?.showToast(message: .AppMenu.RemoveFromReadingListConfirmMessage, toastAction: .removeFromReadingList, url: nil)
            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .readingListItem, value: .pageActionMenu)
        }
    }

    // MARK: Bookmark

    private func getBookmarkSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

        if !isHomePage {
            section.append(PhotonRowActions([getBookmarkLibraryAction(), getBookmarkAction()]))
        } else {
            section.append(PhotonRowActions(getBookmarkLibraryAction()))
        }

        return section
    }

    private func getBookmarkLibraryAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.Bookmarks,
                                     iconString: ImageIdentifiers.bookmarks) { _ in
            self.delegate?.showLibrary(panel: .bookmarks)
        }
    }

    private func getBookmarkAction() -> SingleActionViewModel {
        return isBookmarked ? getRemoveBookmarkAction() : getAddBookmarkAction()
    }

    private func getAddBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.AddBookmark,
                                     alternateTitle: .AppMenu.AddBookmarkAlternateTitle,
                                     iconString: ImageIdentifiers.addToBookmark) { _ in

            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL
            else { return }

            // The method in BVC also handles the toast for this use case
            self.delegate?.addBookmark(url: url.absoluteString, title: tab.title, favicon: tab.displayFavicon)
            TelemetryWrapper.recordEvent(category: .action, method: .add, object: .bookmark, value: .pageActionMenu)
        }
    }

    private func getRemoveBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.RemoveBookmark,
                                     alternateTitle: .AppMenu.RemoveBookmarkAlternateTitle,
                                     iconString: ImageIdentifiers.removeFromBookmark) { _ in

            guard let url = self.tabUrl?.displayURL else { return }

            self.profile.places.deleteBookmarksWithURL(url: url.absoluteString).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(message: .AppMenu.RemoveBookmarkConfirmMessage, toastAction: .removeBookmark, url: url.absoluteString)
                self.removeBookmarkShortcut()
            }

            TelemetryWrapper.recordEvent(category: .action, method: .delete, object: .bookmark, value: .pageActionMenu)
        }
    }

    // MARK: Shortcut

    private func getShortcutAction() -> PhotonRowActions {
        return isPinned ? getRemoveShortcutAction().items : getAddShortcutAction().items
    }

    private func getAddShortcutAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AddToShortcutsActionTitle,
                                     iconString: ImageIdentifiers.addShortcut) { _ in

            guard let url = self.selectedTab?.url?.displayURL,
                  let sql = self.profile.history as? SQLiteHistory
            else { return }

            sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }
                return self.profile.history.addPinnedTopSite(site)

            }.uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(message: .AppMenu.AddPinToShortcutsConfirmMessage, toastAction: .pinPage, url: nil)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pinToTopSites)
        }
    }

    private func getRemoveShortcutAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AppMenu.RemoveFromShortcuts,
                                     iconString: ImageIdentifiers.removeFromShortcut) { _ in

            guard let url = self.selectedTab?.url?.displayURL, let sql = self.profile.history as? SQLiteHistory else { return }

            sql.getSites(forURLs: [url.absoluteString]).bind { val -> Success in
                guard let site = val.successValue?.asArray().first?.flatMap({ $0 }) else {
                    return succeed()
                }

                return self.profile.history.removeFromPinnedTopSites(site)
            }.uponQueue(.main) { result in
                if result.isSuccess {
                    self.delegate?.showToast(message: .AppMenu.RemovePinFromShortcutsConfirmMessage, toastAction: .removePinPage, url: nil)
                }
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .removePinnedSite)
        }
    }

    // MARK: Password

    typealias NavigationHandlerType = ((_ url: URL?) -> Void)
    private func getPasswordAction(navigationController: UINavigationController?) -> PhotonRowActions? {
        guard LoginListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs),
              let navigationController = navigationController
        else { return nil }

        return SingleActionViewModel(title: .AppMenu.AppMenuPasswords,
                                     iconString: ImageIdentifiers.key,
                                     iconType: .Image,
                                     iconAlignment: .left) { _ in

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

    private func append(to items: inout [PhotonRowActions], action: PhotonRowActions?) {
        if let action = action {
            items.append(action)
        }
    }

    private func append(to items: inout [PhotonRowActions], action: [PhotonRowActions]?) {
        if let action = action {
            items.append(contentsOf: action)
        }
    }
}
