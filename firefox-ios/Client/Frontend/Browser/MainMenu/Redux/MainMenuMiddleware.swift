// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import ToolbarKit
import Account

final class MainMenuMiddleware {
    private let logger: Logger
    private let telemetry = MainMenuTelemetry()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
    }

    lazy var mainMenuProvider: Middleware<AppState> = { state, action in
        guard let action = action as? MainMenuAction else { return }

        switch action.actionType {
        case MainMenuActionType.tapCloseMenu:
            self.telemetry.mainMenuDismissed()
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
                    self.dispatchUpdateAccountHeader(accountData: accountData, action: action)
                }
            } else {
                self.dispatchUpdateAccountHeader(action: action)
            }
            store.dispatch(
                MainMenuAction(
                    windowUUID: action.windowUUID,
                    actionType: MainMenuMiddlewareActionType.requestTabInfo
                )
            )
        default:
            break
        }
    }

    private func dispatchUpdateAccountHeader(accountData: AccountData? = nil,
                                             action: MainMenuAction,
                                             icon: UIImage? = nil) {
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
}
