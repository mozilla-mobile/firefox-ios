// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux

class TermsOfUseMiddleware {
    struct DefaultKeys {
        static let acceptedKey = "termsOfUseAccepted"
        static let dismissedKey = "termsOfUseDismissed"
        static let lastShownKey = "termsOfUseLastShownDate"
    }
    private let userDefaults: UserDefaultsInterface

    init(userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    lazy var termsOfUseProvider: Middleware<AppState> = { _, action in
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType else { return }

        switch type {
        case .markAccepted:
            self.userDefaults.set(true, forKey: DefaultKeys.acceptedKey)
            self.userDefaults.set(false, forKey: DefaultKeys.dismissedKey)

        case .markDismissed:
            self.userDefaults.set(true, forKey: DefaultKeys.dismissedKey)
            self.userDefaults.set(Date(), forKey: DefaultKeys.lastShownKey)

        case .markShownThisLaunch:
            break
        }
    }
}
