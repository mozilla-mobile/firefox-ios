// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import Account
import Shared

final class MainMenuMiddleware {
    private struct Options {
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
        static let share = "share"
        static let switchToDesktopSite = "switch_to_desktop_site"
        static let switchToMobileSite = "switch_to_mobile_site"
        static let readerViewTurnOn = "reader_view_turn_on"
        static let readerViewTurnOff = "reader_view_turn_off"
        static let signInAccount = "sign_in_account"
    }

    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var mainMenuProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }
        let isHomepage = action.currentTabInfo?.isHomepage ?? false

        switch action.actionType {
        case MainMenuActionType.tapNavigateToDestination:
            self.handleNavigationDestination(for: action.navigationDestination?.destination,
                                             currentTabInfo: action.currentTabInfo,
                                             and: action.navigationDestination?.url)
        case MainMenuActionType.tapShowDetailsView:
            if action.detailsViewToShow == .tools {
                self.telemetry.optionTapped(with: isHomepage, and: Options.tools)
            } else if action.detailsViewToShow == .save {
                self.telemetry.optionTapped(with: isHomepage, and: Options.save)
            }
        case MainMenuActionType.tapToggleUserAgent:
            guard let defaultIsDesktop = action.currentTabInfo?.isDefaultUserAgentDesktop,
                  let hasChangedUserAgent = action.currentTabInfo?.hasChangedUserAgent
            else { return }
            if defaultIsDesktop {
                if hasChangedUserAgent {
                    self.telemetry.optionTapped(with: isHomepage, and: Options.switchToDesktopSite)
                } else {
                    self.telemetry.optionTapped(with: isHomepage, and: Options.switchToMobileSite)
                }
            } else {
                if hasChangedUserAgent {
                    self.telemetry.optionTapped(with: isHomepage, and: Options.switchToMobileSite)
                } else {
                    self.telemetry.optionTapped(with: isHomepage, and: Options.switchToDesktopSite)
                }
            }
        case MainMenuActionType.tapCloseMenu:
            self.telemetry.closeButtonTapped(isHomepage: isHomepage)
        case GeneralBrowserActionType.showReaderMode:
            guard let isActive = action.isActive else { return }
            let option = isActive ? Options.readerViewTurnOn : Options.readerViewTurnOff
            self.telemetry.optionTapped(with: false, and: option)
        case MainMenuActionType.viewDidLoad:
            if let accountData = self.getAccountData() {
                if let iconURL = accountData.iconURL {
                    GeneralizedImageFetcher().getImageFor(url: iconURL) { [weak self] image in
                        guard let self else { return }
                        self.dispatchUpdateAccountHeader(
                            accountData: accountData,
                            action: action,
                            icon: image)
                    }
                } else {
                    self.dispatchUpdateAccountHeader(
                        accountData: accountData,
                        action: action,
                        icon: nil)
                }
            }
            store.dispatch(
                MainMenuAction(
                    windowUUID: action.windowUUID,
                    actionType: MainMenuMiddlewareActionType.requestTabInfo
                )
            )
        case MainMenuActionType.menuDismissed:
            self.telemetry.menuDismissed(isHomepage: isHomepage)
        default:
            break
        }
    }

    private func dispatchUpdateAccountHeader(accountData: AccountData?,
                                             action: MainMenuAction,
                                             icon: UIImage?) {
        store.dispatch(
            MainMenuAction(
                windowUUID: action.windowUUID,
                actionType: MainMenuMiddlewareActionType.updateAccountHeader,
                accountData: accountData,
                accountIcon: icon
            )
        )
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
           let url = URL(string: str, invalidCharacters: false) {
            iconURL = url
        }

        return AccountData(title: title,
                           subtitle: subtitle,
                           warningIcon: warningIcon,
                           iconURL: iconURL)
    }

    private func handleNavigationDestination(for destination: MainMenuNavigationDestination?,
                                             currentTabInfo: MainMenuTabInfo?,
                                             and urlToVisit: URL?) {
        let isHomepage = currentTabInfo?.isHomepage ?? false
        switch destination {
        case .newTab:
            telemetry.optionTapped(with: isHomepage, and: Options.newTab)
        case .newPrivateTab:
            telemetry.optionTapped(with: isHomepage, and: Options.newPrivateTab)
        case .findInPage:
            telemetry.optionTapped(with: isHomepage, and: Options.findInPage)
        case .bookmarks:
            telemetry.optionTapped(with: isHomepage, and: Options.bookmarks)
        case .history:
            telemetry.optionTapped(with: isHomepage, and: Options.history)
        case .downloads:
            telemetry.optionTapped(with: isHomepage, and: Options.downloads)
        case .passwords:
            telemetry.optionTapped(with: isHomepage, and: Options.passwords)
        case .settings:
            telemetry.optionTapped(with: isHomepage, and: Options.settings)
        case .customizeHomepage:
            telemetry.optionTapped(with: isHomepage, and: Options.customizeHomepage)
        case .goToURL:
            if urlToVisit == SupportUtils.URLForGetHelp {
                telemetry.optionTapped(with: isHomepage, and: Options.getHelp)
            } else if urlToVisit == SupportUtils.URLForWhatsNew {
                telemetry.optionTapped(with: isHomepage, and: Options.newInFirefox)
            }
        case .shareSheet:
            telemetry.optionTapped(with: isHomepage, and: Options.share)
        case .syncSignIn:
            telemetry.optionTapped(with: isHomepage, and: Options.signInAccount)
        default: break
        }
    }
}
