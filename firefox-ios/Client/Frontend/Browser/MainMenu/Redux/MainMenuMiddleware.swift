// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Account
import Shared

@MainActor
final class MainMenuMiddleware: FeatureFlaggable {
    private enum TelemetryAction {
        static let addToShortcuts = "add_to_shortcuts"
        static let bookmarks = "bookmarks"
        static let bookmarkThisPage = "bookmark_this_page"
        static let defaultBrowserSettings = "default_browser_settings"
        static let downloads = "downloads"
        static let editBookmark = "edit_bookmark"
        static let findInPage = "find_in_page"
        static let history = "history"
        static let nightModeTurnOff = "night_mode_turn_off"
        static let nightModeTurnOn = "night_mode_turn_on"
        static let passwords = "passwords"
        static let print = "print"
        static let removeFromShortcuts = "remove_from_shortcuts"
        static let saveAsPDF = "save_as_PDF"
        static let settings = "settings"
        static let share = "share"
        static let signInAccount = "sign_in_account"
        static let siteProtections = "site_protections"
        static let switchToDesktopSite = "switch_to_desktop_site"
        static let switchToMobileSite = "switch_to_mobile_site"
        static let webpageSummary = "webpage_summary"
        static let zoom = "zoom"
    }

    private let logger: Logger
    private let telemetry: MainMenuTelemetry

    init(telemetry: MainMenuTelemetry = MainMenuTelemetry(), logger: Logger = DefaultLogger.shared) {
        self.telemetry = telemetry
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

        case MainMenuActionType.tapToggleUserAgent:
            handleTapToggleUserAgentAction(action: action, isHomepage: isHomepage)

        case MainMenuActionType.tapCloseMenu:
            telemetry.closeButtonTapped(isHomepage: isHomepage)

        case MainMenuActionType.viewDidLoad:
            handleDidInstantiateViewAction(action: action)

        case MainMenuActionType.updateMenuAppearance:
            dispatchUpdateMenuAppearance(action: action)

        case MainMenuActionType.menuDismissed:
            telemetry.menuDismissed(isHomepage: isHomepage)

        case MainMenuActionType.tapZoom:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.zoom)

        case MainMenuActionType.tapAddToBookmarks:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.bookmarkThisPage)

        case MainMenuActionType.tapEditBookmark:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.editBookmark)

        case MainMenuActionType.tapAddToShortcuts:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.addToShortcuts)

        case MainMenuActionType.tapRemoveFromShortcuts:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.removeFromShortcuts)

        case MainMenuActionType.tapToggleNightMode:
            handleTapToggleWebSiteDarkModeAction(action: action, isHomepage: isHomepage)

        default: break
        }
    }

    private func handleTapNavigateToDestinationAction(action: MainMenuAction, isHomepage: Bool) {
        guard let destination = action.navigationDestination?.destination else { return }
        handleTelemetryFor(for: destination,
                           isHomepage: isHomepage,
                           and: action.navigationDestination?.url)
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

    private func handleDidInstantiateViewAction(action: MainMenuAction) {
        dispatchUpdateBannerVisibility(action: action)
        dispatchUpdateMenuAppearance(action: action)
        handleViewDidLoadAction(action: action)
    }

    private func dispatchUpdateBannerVisibility(action: MainMenuAction) {
        store.dispatch(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.updateBannerVisibility,
                isBrowserDefault: DefaultBrowserUtility().isDefaultBrowser
            )
        )
    }

    private func dispatchUpdateMenuAppearance(action: MainMenuAction) {
        store.dispatch(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.updateMenuAppearance,
                isPhoneLandscape: UIDevice().isIphoneLandscape
            )
        )
    }

    private func handleViewDidLoadAction(action: MainMenuAction) {
        store.dispatch(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfo
            )
        )
        store.dispatch(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.requestTabInfoForSiteProtectionsHeader
            )
        )
    }

    private func handleTapToggleWebSiteDarkModeAction(action: MainMenuAction, isHomepage: Bool) {
        guard let isActionOn = action.telemetryInfo?.isActionOn else { return }
        let option = isActionOn ? TelemetryAction.nightModeTurnOn : TelemetryAction.nightModeTurnOff
        telemetry.mainMenuOptionTapped(with: isHomepage, and: option)
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

        case .printSheet:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.print)

        case .shareSheet:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.share)

        case .saveAsPDF:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.saveAsPDF)

        case .syncSignIn:
            telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.signInAccount)

        case .editBookmark:
            self.telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.editBookmark)

        case .zoom:
            self.telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.zoom)

        case .siteProtections:
            self.telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.siteProtections)

        case .defaultBrowser:
            self.telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.defaultBrowserSettings)

        case .webpageSummary: break
            self.telemetry.mainMenuOptionTapped(with: isHomepage, and: TelemetryAction.webpageSummary)
        }
    }
}
