// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Account
import Shared

final class MainMenuMiddleware: FeatureFlaggable {
    private enum TelemetryAction {
        static let newTab = "new_tab"
        static let newPrivateTab = "new_private_tab"
        static let findInPage = "find_in_page"
        static let bookmarks = "bookmarks"
        static let history = "history"
        static let downloads = "downloads"
        static let passwords = "passwords"
        static let settings = "settings"
        static let customizeHomepage = "customize_homepage"
        static let getHelp = "get_help"
        static let newInFirefox = "new_in_firefox"
        static let tools = "tools"
        static let save = "save"
        static let print = "print"
        static let share = "share"
        static let saveAsPDF = "save_as_PDF"
        static let switchToDesktopSite = "switch_to_desktop_site"
        static let switchToMobileSite = "switch_to_mobile_site"
        static let readerViewTurnOn = "reader_view_turn_on"
        static let readerViewTurnOff = "reader_view_turn_off"
        static let signInAccount = "sign_in_account"
        static let zoom = "zoom"
        static let reportBrokenSite = "report_broken_site"
        static let bookmarkThisPage = "bookmark_this_page"
        static let editBookmark = "edit_bookmark"
        static let addToShortcuts = "add_to_shortcuts"
        static let removeFromShortcuts = "remove_from_shortcuts"
        static let saveToReadingList = "save_to_reading_list"
        static let removeFromReadingList = "remove_from_reading_list"
        static let nightModeTurnOn = "night_mode_turn_on"
        static let nightModeTurnOff = "night_mode_turn_off"
        static let back = "back"
    }

    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    private var isMenuRedesignOn: Bool {
        featureFlags.isFeatureEnabled(.menuRedesign, checking: .buildOnly)
    }

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var mainMenuProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }
        let isHomepage = action.telemetryInfo?.isHomepage ?? false

        self.handleMainMenuActions(action: action, isHomepage: isHomepage)
    }

    private func handleMainMenuActions(action: MainMenuAction, isHomepage: Bool) {
        switch action.actionType {
        case MainMenuActionType.tapNavigateToDestination:
            handleTapNavigateToDestinationAction(action: action, isHomepage: isHomepage)

        case MainMenuActionType.tapShowDetailsView:
            handleTapShowDetailsViewAction(action: action, isHomepage: isHomepage)

        case MainMenuActionType.tapToggleUserAgent:
            handleTapToggleUserAgentAction(action: action, isHomepage: isHomepage)

        case MainMenuActionType.tapCloseMenu:
            telemetry.closeButtonTapped(isHomepage: isHomepage)

        case GeneralBrowserActionType.showReaderMode:
            handleShowReaderModeAction(action: action)

        case MainMenuActionType.didInstantiateView:
            handleDidInstantiateViewAction(action: action)

        case MainMenuActionType.viewDidLoad:
            handleViewDidLoadAction(action: action)

        case MainMenuActionType.menuDismissed:
            telemetry.menuDismissed(isHomepage: isHomepage)

        case MainMenuDetailsActionType.tapZoom:
            telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.zoom)

        case MainMenuDetailsActionType.tapReportBrokenSite:
            telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.reportBrokenSite)

        case MainMenuDetailsActionType.tapAddToBookmarks:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.bookmarkThisPage)

        case MainMenuDetailsActionType.tapEditBookmark:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.editBookmark)

        case MainMenuDetailsActionType.tapAddToShortcuts:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.addToShortcuts)

        case MainMenuDetailsActionType.tapRemoveFromShortcuts:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.removeFromShortcuts)

        case MainMenuDetailsActionType.tapAddToReadingList:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.saveToReadingList)

        case MainMenuDetailsActionType.tapRemoveFromReadingList:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.removeFromReadingList)

        case MainMenuDetailsActionType.tapToggleNightMode, MainMenuActionType.tapToggleNightMode:
            handleTapToggleNightModeAction(action: action, isHomepage: isHomepage)

        case MainMenuDetailsActionType.tapBackToMainMenu:
            handleTapBackToMainMenuAction(action: action, isHomepage: isHomepage)

        case MainMenuDetailsActionType.tapDismissView:
            telemetry.closeButtonTapped(isHomepage: isHomepage)

        default: break
        }
    }

    private func handleTapNavigateToDestinationAction(action: MainMenuAction, isHomepage: Bool) {
        guard let destination = action.navigationDestination?.destination else { return }
        handleTelemetryFor(for: destination,
                           isHomepage: isHomepage,
                           and: action.navigationDestination?.url)
    }

    private func handleTapShowDetailsViewAction(action: MainMenuAction, isHomepage: Bool) {
        if action.detailsViewToShow == .tools {
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.tools)
        } else if action.detailsViewToShow == .save {
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.save)
        }
    }

    private func handleTapToggleUserAgentAction(action: MainMenuAction, isHomepage: Bool) {
        guard let defaultIsDesktop = action.telemetryInfo?.isDefaultUserAgentDesktop,
              let hasChangedUserAgent = action.telemetryInfo?.hasChangedUserAgent
        else { return }
        if defaultIsDesktop {
            let option = hasChangedUserAgent ? TelemetryAction.switchToDesktopSite : TelemetryAction.switchToMobileSite
            telemetry.mainMenuOptionTapped(with: isHomepage, and: option)
        } else {
            let option = hasChangedUserAgent ? TelemetryAction.switchToMobileSite : TelemetryAction.switchToDesktopSite
            telemetry.mainMenuOptionTapped(with: isHomepage, and: option)
        }
    }

    private func handleShowReaderModeAction(action: MainMenuAction) {
        guard let isActionOn = action.telemetryInfo?.isActionOn else { return }
        let option = isActionOn ? TelemetryAction.readerViewTurnOn : TelemetryAction.readerViewTurnOff
        telemetry.toolsSubmenuOptionTapped(with: false, and: option)
    }

    private func handleDidInstantiateViewAction(action: MainMenuAction) {
        guard !isMenuRedesignOn else { return }
        guard let accountData = getAccountData() else {
            dispatchUpdateAccountHeader(action: action)
            return
        }

        if let iconURL = accountData.iconURL {
            GeneralizedImageFetcher().getImageFor(url: iconURL) { [weak self] image in
                guard let self else { return }
                self.dispatchUpdateAccountHeader(
                    accountData: accountData,
                    action: action,
                    icon: image)
            }
        } else {
            dispatchUpdateAccountHeader(accountData: accountData, action: action)
        }
    }

    private func dispatchUpdateAccountHeader(
        accountData: AccountData? = nil,
        action: MainMenuAction,
        icon: UIImage? = nil
    ) {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.updateAccountHeader,
                accountData: accountData,
                accountIcon: icon
            )
        )
    }

    private func handleViewDidLoadAction(action: MainMenuAction) {
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        store.dispatchLegacy(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfoForSiteProtectionsHeader
            )
        )
    }

    private func handleTapToggleNightModeAction(action: MainMenuAction, isHomepage: Bool) {
        guard let isActionOn = action.telemetryInfo?.isActionOn else { return }
        let option = isActionOn ? TelemetryAction.nightModeTurnOn : TelemetryAction.nightModeTurnOff
        telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: option)
    }

    private func handleTapBackToMainMenuAction(action: MainMenuAction, isHomepage: Bool) {
        guard let submenuType = action.telemetryInfo?.submenuType else { return }
        if submenuType == .save {
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.back)
        } else {
            telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.back)
        }
    }

    private func getAccountData() -> AccountData? {
        let rustAccount = RustFirefoxAccounts.shared
        let needsReAuth = rustAccount.accountNeedsReauth()

        guard let userProfile = rustAccount.userProfile else { return nil }

        let title: String = {
            if needsReAuth { return .MainMenu.Account.SyncErrorTitle }
            return userProfile.displayName ?? userProfile.email
        }()

        let subtitle: String? = needsReAuth ? .MainMenu.Account.SyncErrorDescription : nil
        let warningIcon: String? = needsReAuth ? StandardImageIdentifiers.Large.warningFill : nil

        var iconURL: URL?
        if let str = rustAccount.userProfile?.avatarUrl,
           let url = URL(string: str) {
            iconURL = url
        }

        return AccountData(title: title,
                           subtitle: subtitle,
                           warningIcon: warningIcon,
                           iconURL: iconURL)
    }

    private func handleTelemetryFor(for navigationDestination: MainMenuNavigationDestination,
                                    isHomepage: Bool,
                                    and urlToVisit: URL?) {
        switch navigationDestination {
        case .newTab:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.newTab)

        case .newPrivateTab:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.newPrivateTab)

        case .findInPage:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.findInPage)

        case .bookmarks:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.bookmarks)

        case .history:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.history)

        case .downloads:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.downloads)

        case .passwords:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.passwords)

        case .settings:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.settings)

        case .customizeHomepage:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.customizeHomepage)

        case .goToURL:
            if urlToVisit == SupportUtils.URLForGetHelp {
                telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.getHelp)
            } else if urlToVisit == SupportUtils.URLForWhatsNew {
                telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.newInFirefox)
            }

        case .printSheet:
            telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.print)

        case .shareSheet:
            telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.share)

        case .saveAsPDF:
            telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.saveAsPDF)

        case .syncSignIn:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.signInAccount)

        case .editBookmark:
            self.telemetry.saveSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.editBookmark)

        case .zoom:
            self.telemetry.toolsSubmenuOptionTapped(with: isHomepage, and: TelemetryAction.zoom)

        case .siteProtections: break
            // TODO: FXIOS-12554 [Menu Redesign] Handle Telemetry for menu
        }
    }
}
