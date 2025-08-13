// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux
import Shared

// TODO: FXIOS-12947 - Add tests for TermsOfUse Feature
@MainActor
class TermsOfUseMiddleware {
    private let prefs: Prefs
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.prefs = profile.prefs
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
                self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)

            case TermsOfUseActionType.markDismissed:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseDismissedDate)

            case TermsOfUseActionType.markFirstShown:
                self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)
            }
        }
    }
}
