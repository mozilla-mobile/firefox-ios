// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared
import Storage
import UIKit
import SwiftUI
import Common

protocol ToolBarActionMenuDelegate: AnyObject {
    func updateToolbarState()
    func addBookmark(url: String, title: String?)

    @discardableResult
    func openURLInNewTab(_ url: URL?, isPrivate: Bool) -> Tab
    func openNewTabFromMenu(focusLocationField: Bool, isPrivate: Bool)

    func showLibrary(panel: LibraryPanelType)
    func showViewController(viewController: UIViewController)
    func showToast(_ bookmarkURL: URL?, _ title: String?, message: String, toastAction: MenuButtonToastAction)
    func showFindInPage()
    func showCustomizeHomePage()
    func showZoomPage(tab: Tab)
    func showCreditCardSettings()
    func showSignInView(fxaParameters: FxASignInViewParameters)
    func showFilePicker(fileURL: URL)
    func showPasswordGeneratorBottomSheet(generatedPassword: String, fillPasswordField: @escaping (String) -> Void)
}

extension ToolBarActionMenuDelegate {
    func showToast(_ bookmarkURL: URL? = nil, _ title: String? = nil, message: String, toastAction: MenuButtonToastAction) {
        showToast(bookmarkURL, title, message: message, toastAction: toastAction)
    }
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
    case closeTab
    case downloadPDF
}

/// MainMenuActionHelper handles the main menu (hamburger menu) in the toolbar.
/// There is three different types of main menu:
///     - The home page menu, determined with isHomePage variable
///     - The file URL menu, shown when the user is on a url of type `file://`
///     - The site menu, determined by the absence of isHomePage and isFileURL
class MainMenuActionHelper: PhotonActionSheetProtocol,
                            FeatureFlaggable,
                            CanRemoveQuickActionBookmark,
                            AppVersionUpdateCheckerProtocol {
    typealias SendToDeviceDelegate = InstructionsViewDelegate & DevicePickerViewControllerDelegate

    private let isHomePage: Bool
    private let buttonView: UIButton
    private let toastContainer: UIView
    private let selectedTab: Tab?
    private let tabUrl: URL?
    private let isFileURL: Bool

    let themeManager: ThemeManager
    var bookmarksHandler: BookmarksHandler
    let profile: Profile
    let tabManager: TabManager
    var windowUUID: WindowUUID { tabManager.windowUUID }

    weak var delegate: ToolBarActionMenuDelegate?
    weak var sendToDeviceDelegate: SendToDeviceDelegate?
    weak var navigationHandler: BrowserNavigationHandler?

    /// MainMenuActionHelper init
    /// - Parameters:
    ///   - profile: the user's profile
    ///   - tabManager: the tab manager
    ///   - buttonView: the view from which the menu will be shown
    ///   - toastContainer: the view hosting a toast alert
    ///   - showFXASyncAction: the closure that will be executed for the sync action in the library section
    init(profile: Profile,
         tabManager: TabManager,
         buttonView: UIButton,
         toastContainer: UIView,
         themeManager: ThemeManager = AppContainer.shared.resolve()
    ) {
        self.profile = profile
        self.bookmarksHandler = profile.places
        self.tabManager = tabManager
        self.buttonView = buttonView
        self.toastContainer = toastContainer

        self.selectedTab = tabManager.selectedTab
        self.tabUrl = selectedTab?.url
        self.isFileURL = tabUrl?.isFileURL ?? false
        self.isHomePage = selectedTab?.isFxHomeTab ?? false
        self.themeManager = themeManager
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
        var url: String?

        if let tabUrl = tabUrl, tabUrl.isReaderModeURL, let tabUrlDecoded = tabUrl.decodeReaderModeURL {
            url = tabUrlDecoded.absoluteString
        } else {
            url = tabUrl?.absoluteString
        }

        guard let url = url else {
            dataLoadingCompletion?()
            return
        }

        let group = DispatchGroup()
        getIsBookmarked(url: url, group: group)
        getIsPinned(url: url, group: group)
        getIsInReadingList(url: url, group: group)

        let dataQueue = DispatchQueue.global()
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
        profile.pinnedSites.isPinnedTopSite(url).uponQueue(dataQueue) { result in
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

        let syncAction = syncMenuButton()
        append(to: &section, action: syncAction)

        return section
    }

    private func getFirstMiscSection(_ navigationController: UINavigationController?) -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

        if !isHomePage && !isFileURL {
            if featureFlags.isFeatureEnabled(.zoomFeature, checking: .buildOnly) {
                let zoomAction = getZoomAction()
                append(to: &section, action: zoomAction)
            }

            let findInPageAction = getFindInPageAction()
            append(to: &section, action: findInPageAction)

            let desktopSiteAction = getRequestDesktopSiteAction()
            append(to: &section, action: desktopSiteAction)
        }

        if featureFlags.isFeatureEnabled(.nightMode, checking: .buildOnly) {
            let nightModeAction = getNightModeAction()
            append(to: &section, action: nightModeAction)
        }

        let passwordsAction = getPasswordAction(navigationController: navigationController)
        append(to: &section, action: passwordsAction)

        if !isHomePage && !isFileURL {
            let reportSiteIssueAction = getReportSiteIssueAction()
            append(to: &section, action: reportSiteIssueAction)
        }

//        // TODO: FXIOS-9659 [TEMPORARY] Remove password generator prompt menu button after this ticket has been implemented
//        if featureFlags.isFeatureEnabled(.passwordGenerator, checking: .buildOnly) {
//            let showPasswordGeneratorPromptAction = getShowPasswordGeneratorPromptAction()
//            append(to: &section, action: showPasswordGeneratorPromptAction)
//        }

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

            if let tab = self.selectedTab,
                let url = tab.canonicalURL?.displayURL,
                url.lastPathComponent.suffix(4) == ".pdf" {
                let downloadPDFAction = getDownloadPDFAction()
                append(to: &section, action: downloadPDFAction)
            }

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

    private func getNewTabAction() -> PhotonRowActions? {
        guard let tab = selectedTab else { return nil }
        return SingleActionViewModel(title: tab.isPrivate ? .LegacyAppMenu.NewPrivateTab : .LegacyAppMenu.NewTab,
                                     iconString: StandardImageIdentifiers.Large.plus) { _ in
            let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) != .homePage
            self.delegate?.openNewTabFromMenu(focusLocationField: shouldFocusLocationField, isPrivate: tab.isPrivate)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .createNewTab)
        }.items
    }

    private func getHistoryLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuHistory,
                                     iconString: StandardImageIdentifiers.Large.history) { _ in
            self.delegate?.showLibrary(panel: .history)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .viewHistoryPanel)
        }.items
    }

    private func getDownloadsLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuDownloads,
                                     iconString: StandardImageIdentifiers.Large.download) { _ in
            self.delegate?.showLibrary(panel: .downloads)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .viewDownloadsPanel)
        }.items
    }

    // MARK: Zoom

    private func getZoomAction() -> PhotonRowActions? {
        guard let tab = selectedTab else { return nil }
        let zoomLevel = NumberFormatter.localizedString(from: NSNumber(value: tab.pageZoom), number: .percent)
        let title = String(format: .LegacyAppMenu.ZoomPageTitle, zoomLevel)
        let zoomAction = SingleActionViewModel(title: title,
                                               iconString: StandardImageIdentifiers.Large.pageZoom) { _ in
            self.delegate?.showZoomPage(tab: tab)
        }.items
        return zoomAction
    }

    private func getFindInPageAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuFindInPageTitleString,
                                     iconString: StandardImageIdentifiers.Large.search) { _ in
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
        // swiftlint:disable line_length
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .LegacyAppMenu.AppMenuViewDesktopSiteTitleString : .LegacyAppMenu.AppMenuViewMobileSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? StandardImageIdentifiers.Large.deviceDesktop : StandardImageIdentifiers.Large.deviceMobile
            siteTypeTelemetryObject = .requestDesktopSite
        } else {
            toggleActionTitle = tab.changedUserAgent ? .LegacyAppMenu.AppMenuViewMobileSiteTitleString : .LegacyAppMenu.AppMenuViewDesktopSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? StandardImageIdentifiers.Large.deviceMobile : StandardImageIdentifiers.Large.deviceDesktop
            siteTypeTelemetryObject = .requestMobileSite
        }
        // swiftlint:enable line_length

        return SingleActionViewModel(title: toggleActionTitle,
                                     iconString: toggleActionIcon) { _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(
                    forUrl: url,
                    isChangedUA: tab.changedUserAgent,
                    isPrivate: tab.isPrivate
                )
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
            }
        }.items
    }

    private func getCopyAction() -> PhotonRowActions? {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuCopyLinkTitleString,
                                     iconString: StandardImageIdentifiers.Large.link) { _ in
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
            if let url = self.selectedTab?.canonicalURL?.displayURL {
                UIPasteboard.general.url = url
                self.delegate?.showToast(message: .LegacyAppMenu.AppMenuCopyURLConfirmMessage, toastAction: .copyUrl)
            }
        }.items
    }

    private func getSendToDevice() -> PhotonRowActions {
        let uuid = windowUUID
        return SingleActionViewModel(title: .LegacyAppMenu.TouchActions.SendLinkToDeviceTitle,
                                     iconString: StandardImageIdentifiers.Large.deviceDesktopSend) { _ in
            guard let delegate = self.sendToDeviceDelegate,
                  let selectedTab = self.selectedTab,
                  let url = selectedTab.canonicalURL?.displayURL
            else { return }

            let themeColors = self.themeManager.getCurrentTheme(for: uuid).colors
            let colors = SendToDeviceHelper.Colors(defaultBackground: themeColors.layer1,
                                                   textColor: themeColors.textPrimary,
                                                   iconColor: themeColors.iconPrimary)

            let shareItem = ShareItem(url: url.absoluteString,
                                      title: selectedTab.title)
            let helper = SendToDeviceHelper(shareItem: shareItem,
                                            profile: self.profile,
                                            colors: colors,
                                            delegate: delegate)

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sendToDevice)
            self.delegate?.showViewController(viewController: helper.initialViewController())
        }.items
    }

    private func getReportSiteIssueAction() -> PhotonRowActions? {
        guard featureFlags.isFeatureEnabled(.reportSiteIssue, checking: .buildOnly) else { return nil }

        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuReportSiteIssueTitleString,
                                     iconString: StandardImageIdentifiers.Large.lightbulb) { _ in
            guard let tabURL = self.selectedTab?.url?.absoluteString else { return }
            self.delegate?.openURLInNewTab(SupportUtils.URLForReportSiteIssue(tabURL), isPrivate: false)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .reportSiteIssue)
        }.items
    }

    // TODO: FXIOS-9659 [TEMPORARY] Remove password generator prompt menu button after this ticket has been implemented
//    private func getShowPasswordGeneratorPromptAction() -> PhotonRowActions? {
//        guard featureFlags.isFeatureEnabled(.passwordGenerator, checking: .buildOnly) else { return nil }
//
//        // This method will be removed so the title not being localized doesn't matter
//        return SingleActionViewModel(title: "Show Password Generator Prompt",
//                                     iconString: StandardImageIdentifiers.Large.lock) { _ in
//            self.delegate?.showPasswordGeneratorBottomSheet()
//        }.items
//    }

    private func getHelpAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.Help,
                                     iconString: StandardImageIdentifiers.Large.helpCircle) { _ in
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.openURLInNewTab(url, isPrivate: self.tabManager.selectedTab?.isPrivate ?? false)
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .help)
        }.items
    }

    private func getCustomizeHomePageAction() -> PhotonRowActions? {
        return SingleActionViewModel(title: .LegacyAppMenu.CustomizeHomePage,
                                     iconString: StandardImageIdentifiers.Large.edit) { _ in
            self.delegate?.showCustomizeHomePage()
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .customizeHomePage)
        }.items
    }

    private func getSettingsAction() -> PhotonRowActions {
        let openSettings = SingleActionViewModel(title: .LegacyAppMenu.AppMenuSettingsTitleString,
                                                 iconString: StandardImageIdentifiers.Large.settings) { _ in
            TelemetryWrapper.recordEvent(category: .action, method: .open, object: .settings)

            // Wait to show settings in async dispatch since hamburger menu is still showing at that time
            DispatchQueue.main.async {
                self.navigationHandler?.show(settings: .general)
            }
        }.items
        return openSettings
    }

    private func getNightModeAction() -> [PhotonRowActions] {
        var items: [PhotonRowActions] = []

        let nightModeEnabled = NightModeHelper.isActivated()
        let nightModeTitle: String = if nightModeEnabled {
            .LegacyAppMenu.AppMenuTurnOffNightMode
        } else {
            .LegacyAppMenu.AppMenuTurnOnNightMode
        }

        let nightMode = SingleActionViewModel(
            title: nightModeTitle,
            iconString: StandardImageIdentifiers.Large.nightMode,
            isEnabled: nightModeEnabled
        ) { _ in
            NightModeHelper.toggle()

            if NightModeHelper.isActivated() {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeEnabled)
            } else {
                TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .nightModeDisabled)
            }

            self.themeManager.applyThemeUpdatesToWindows()
        }.items
        items.append(nightMode)

        return items
    }

    private func syncMenuButton() -> PhotonRowActions? {
        let action: (SingleActionViewModel) -> Void = { [weak self] action in
            let fxaParams = FxALaunchParams(entrypoint: .browserMenu, query: [:])
            let parameters = FxASignInViewParameters(launchParameters: fxaParams,
                                                     flowType: .emailLoginFlow,
                                                     referringPage: .appMenu)
            self?.delegate?.showSignInView(fxaParameters: parameters)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .signIntoSync)
        }

        let rustAccount = RustFirefoxAccounts.shared
        let needsReAuth = rustAccount.accountNeedsReauth()

        guard let userProfile = rustAccount.userProfile else {
            return SingleActionViewModel(title: .LegacyAppMenu.SyncAndSaveData,
                                         iconString: StandardImageIdentifiers.Large.sync,
                                         tapHandler: action).items
        }

        let title: String = {
            if rustAccount.accountNeedsReauth() {
                return .FxAAccountVerifyPassword
            }
            return userProfile.displayName ?? userProfile.email
        }()

        let warningImage = StandardImageIdentifiers.Large.warningFill
        let avatarImage = StandardImageIdentifiers.Large.avatarCircle
        let iconString = needsReAuth ? warningImage : avatarImage

        var iconURL: URL?
        if let str = rustAccount.userProfile?.avatarUrl,
            let url = URL(string: str, invalidCharacters: false) {
            iconURL = url
        }
        let iconType: PhotonActionSheetIconType = needsReAuth ? .Image : .URL
        let syncOption = SingleActionViewModel(title: title,
                                               iconString: iconString,
                                               iconURL: iconURL,
                                               iconType: iconType,
                                               needsIconActionableTint: needsReAuth,
                                               tapHandler: action).items
        return syncOption
    }

    // MARK: Whats New

    private func getWhatsNewAction() -> PhotonRowActions? {
        var whatsNewAction: PhotonRowActions?
        let showBadgeForWhatsNew = shouldShowWhatsNew()
        if showBadgeForWhatsNew {
            // Set the version number of the app, so the What's new will stop showing
            profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest)

            // Redraw the toolbar so the badge hides from the appMenu button.
            delegate?.updateToolbarState()
        }

        whatsNewAction = SingleActionViewModel(title: .LegacyAppMenu.WhatsNewString,
                                               iconString: StandardImageIdentifiers.Large.whatsNew,
                                               isEnabled: showBadgeForWhatsNew) { _ in
            if let whatsNewURL = SupportUtils.URLForWhatsNew {
                TelemetryWrapper.recordEvent(category: .action, method: .open, object: .whatsNew)
                self.delegate?.openURLInNewTab(whatsNewURL, isPrivate: self.tabManager.selectedTab?.isPrivate ?? false)
            }
        }.items
        return whatsNewAction
    }

    private func shouldShowWhatsNew() -> Bool {
        return isMajorVersionUpdate(using: profile) && DeviceInfo.hasConnectivity()
    }

    // MARK: Share

    private func getShareFileAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuSharePageTitleString,
                                     iconString: StandardImageIdentifiers.Large.share) { _ in
            guard let tab = self.selectedTab,
                  let url = tab.url
            else { return }

            self.share(fileURL: url, buttonView: self.buttonView)
        }.items
    }

    private func getShareAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.Share,
                                     iconString: StandardImageIdentifiers.Large.share) { _ in
            guard let tab = self.selectedTab, let url = tab.canonicalURL?.displayURL else { return }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)

            guard let temporaryDocument = tab.temporaryDocument else {
                self.navigationHandler?.showShareExtension(
                    url: url,
                    sourceView: self.buttonView,
                    toastContainer: self.toastContainer,
                    popoverArrowDirection: .any)
                return
            }

            temporaryDocument.getURL { tempDocURL in
                DispatchQueue.main.async {
                    // If we successfully got a temp file URL, share it like a downloaded file,
                    // otherwise present the ordinary share menu for the web URL.
                    if let tempDocURL = tempDocURL,
                       tempDocURL.isFileURL {
                        self.share(fileURL: tempDocURL, buttonView: self.buttonView)
                    } else {
                        self.navigationHandler?.showShareExtension(
                            url: url,
                            sourceView: self.buttonView,
                            toastContainer: self.toastContainer,
                            popoverArrowDirection: .any)
                    }
                }
            }
        }.items
    }

    private func getDownloadPDFAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuDownloadPDF,
                                     iconString: StandardImageIdentifiers.Large.folder) { _ in
            guard let tab = self.selectedTab, let temporaryDocument = tab.temporaryDocument else { return }
                temporaryDocument.getURL { fileURL in
                    DispatchQueue.main.async {
                        guard let fileURL = fileURL else {return}
                        self.delegate?.showFilePicker(fileURL: fileURL)
                    }
                }
        }.items
    }

    // Main menu option Share page with when opening a file
    private func share(fileURL: URL, buttonView: UIView) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .sharePageWith)
        navigationHandler?.showShareExtension(
            url: fileURL,
            sourceView: buttonView,
            toastContainer: toastContainer,
            popoverArrowDirection: .any)
    }

    // MARK: Reading list

    private func getReadingListSection() -> [PhotonRowActions] {
        var section = [PhotonRowActions]()

        let libraryAction = getReadingListLibraryAction()
        if !isHomePage, selectedTab?.readerModeAvailableOrActive ?? false {
            let readingListAction = getReadingListAction()
            section.append(PhotonRowActions([libraryAction, readingListAction]))
        } else {
            section.append(PhotonRowActions(libraryAction))
        }

        return section
    }

    private func getReadingListLibraryAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.ReadingList,
                                     iconString: StandardImageIdentifiers.Large.readingList) { _ in
            self.delegate?.showLibrary(panel: .readingList)
        }
    }

    private func getReadingListAction() -> SingleActionViewModel {
        return isInReadingList ? getRemoveReadingListAction() : getAddReadingListAction()
    }

    private func getAddReadingListAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.AddReadingList,
                                     iconString: StandardImageIdentifiers.Large.readingListAdd) { _ in
            guard let tab = self.selectedTab,
                  let url = self.tabUrl?.displayURL
            else { return }

            self.profile.readingList.createRecordWithURL(
                url.absoluteString,
                title: tab.title ?? "",
                addedBy: UIDevice.current.name
            )
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .add,
                object: .readingListItem,
                value: .pageActionMenu
            )
            self.delegate?.showToast(message: .LegacyAppMenu.AddToReadingListConfirmMessage, toastAction: .addToReadingList)
        }
    }

    private func getRemoveReadingListAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.RemoveReadingList,
                                     iconString: StandardImageIdentifiers.Large.delete) { _ in
            guard let url = self.tabUrl?.displayURL?.absoluteString,
                  let record = self.profile.readingList.getRecordWithURL(url).value.successValue
            else { return }

            self.profile.readingList.deleteRecord(record, completion: nil)
            self.delegate?.showToast(message: .LegacyAppMenu.RemoveFromReadingListConfirmMessage,
                                     toastAction: .removeFromReadingList)
            TelemetryWrapper.recordEvent(category: .action,
                                         method: .delete,
                                         object: .readingListItem,
                                         value: .pageActionMenu)
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
        return SingleActionViewModel(title: .LegacyAppMenu.Bookmarks,
                                     iconString: StandardImageIdentifiers.Large.bookmarkTrayFill) { _ in
            self.delegate?.showLibrary(panel: .bookmarks)
        }
    }

    private func getBookmarkAction() -> SingleActionViewModel {
        return isBookmarked ? getRemoveBookmarkAction() : getAddBookmarkAction()
    }

    private func getAddBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.AddBookmark,
                                     iconString: StandardImageIdentifiers.Large.bookmark) { _ in
            guard let tab = self.selectedTab,
                  let url = tab.canonicalURL?.displayURL
            else { return }

            // The method in BVC also handles the toast for this use case
            self.delegate?.addBookmark(url: url.absoluteString, title: tab.title)
            TelemetryWrapper.recordEvent(
                category: .action,
                method: .add,
                object: .bookmark,
                value: .pageActionMenu
            )
        }
    }

    private func getRemoveBookmarkAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.RemoveBookmark,
                                     iconString: StandardImageIdentifiers.Large.bookmarkSlash) { _ in
            guard let url = self.tabUrl?.displayURL else { return }

            self.profile.places.deleteBookmarksWithURL(url: url.absoluteString).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(
                    message: .LegacyAppMenu.RemoveBookmarkConfirmMessage,
                    toastAction: .removeBookmark
                )
                self.removeBookmarkShortcut()
            }

            TelemetryWrapper.recordEvent(
                category: .action,
                method: .delete,
                object: .bookmark,
                value: .pageActionMenu
            )
        }
    }

    // MARK: Shortcut

    private func getShortcutAction() -> PhotonRowActions {
        return isPinned ? getRemoveShortcutAction().items : getAddShortcutAction().items
    }

    private func getAddShortcutAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .AddToShortcutsActionTitle,
                                     iconString: StandardImageIdentifiers.Large.pin) { _ in
            guard let url = self.selectedTab?.url?.displayURL,
                  let title = self.selectedTab?.displayTitle else { return }
            let site = Site(url: url.absoluteString, title: title)
            self.profile.pinnedSites.addPinnedTopSite(site).uponQueue(.main) { result in
                guard result.isSuccess else { return }
                self.delegate?.showToast(message: .LegacyAppMenu.AddPinToShortcutsConfirmMessage, toastAction: .pinPage)
            }

            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .pinToTopSites)
        }
    }

    private func getRemoveShortcutAction() -> SingleActionViewModel {
        return SingleActionViewModel(title: .LegacyAppMenu.RemoveFromShortcuts,
                                     iconString: StandardImageIdentifiers.Large.pinSlash) { _ in
            guard let url = self.selectedTab?.url?.displayURL,
                  let title = self.selectedTab?.displayTitle else { return }
            let site = Site(url: url.absoluteString, title: title)
            self.profile.pinnedSites.removeFromPinnedTopSites(site).uponQueue(.main) { result in
                if result.isSuccess {
                    self.delegate?.showToast(
                        message: .LegacyAppMenu.RemovePinFromShortcutsConfirmMessage,
                        toastAction: .removePinPage
                    )
                }
            }
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .removePinnedSite)
        }
    }

    // MARK: Password

    private func getPasswordAction(navigationController: UINavigationController?) -> PhotonRowActions? {
        guard PasswordManagerListViewController.shouldShowAppMenuShortcut(forPrefs: profile.prefs) else { return nil }
        TelemetryWrapper.recordEvent(category: .action, method: .open, object: .logins)
        return SingleActionViewModel(title: .LegacyAppMenu.AppMenuPasswords,
                                     iconString: StandardImageIdentifiers.Large.login,
                                     iconType: .Image,
                                     iconAlignment: .left) { _ in
            self.navigationHandler?.show(settings: .password)
        }.items
    }

    // MARK: - Convenience

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
