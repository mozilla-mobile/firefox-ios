// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux
import Foundation

// TODO: FXIOS-12947 - Add tests for TermsOfUse Feature and use profile.prefs
// instead of User Defaults
@MainActor
class TermsOfUseMiddleware {
    struct DefaultKeys {
        static let acceptedKey = "termsOfUseAccepted"
        static let dismissedKey = "termsOfUseDismissed"
        static let lastShownKey = "termsOfUseLastShownDate"
    }
    private let userDefaults: UserDefaultsInterface
    private let logger: Logger

    init(userDefaults: UserDefaultsInterface = UserDefaults.standard,
         logger: Logger = DefaultLogger.shared) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    lazy var termsOfUseProvider: Middleware<AppState> = { _, action in
        // TODO: FXIOS-12557 We assume that we are isolated to the Main Actor
        // because we dispatch to the main thread in the store. We will want
        // to also isolate that to the @MainActor to remove this.
        guard Thread.isMainThread else {
            self.logger.log(
                "Terms of Use Middleware is not being called from the main thread!",
                level: .fatal,
                category: .coordinator
            )
            return
        }

        MainActor.assumeIsolated {
            guard let action = action as? TermsOfUseAction,
                  let type = action.actionType as? TermsOfUseActionType else { return }

            switch type {
            case TermsOfUseActionType.markAccepted:
                self.userDefaults.set(true, forKey: DefaultKeys.acceptedKey)
                self.userDefaults.set(false, forKey: DefaultKeys.dismissedKey)

            case TermsOfUseActionType.markDismissed:
                self.userDefaults.set(true, forKey: DefaultKeys.dismissedKey)
                self.userDefaults.set(Date(), forKey: DefaultKeys.lastShownKey)

            case TermsOfUseActionType.markShownThisLaunch:
                break
            }
        }
    }
}
