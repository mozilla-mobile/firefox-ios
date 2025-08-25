// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux
import Shared
import Glean

// TODO: FXIOS-12947 - Add tests for TermsOfUse Feature
@MainActor
class TermsOfUseMiddleware {
    private let termsOfUseVersion: Int64 = 4
    private let termsOfUseSurface = "bottom_sheet"

    private let prefs: Prefs
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.prefs = profile.prefs
        self.logger = logger
    }

    lazy var termsOfUseProvider: Middleware<AppState> = { _, action in
        self.handleTermsOfUseAction(action)
    }

    private func handleTermsOfUseAction(_ action: Action) {
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
                self.recordAcceptance()
            case TermsOfUseActionType.markDismissed:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseDismissedDate)
            case TermsOfUseActionType.markShown:
                self.recordImpression()
            }
        }
    }

    private func recordAcceptance() {
        self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        self.prefs.setString(String(termsOfUseVersion), forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        // Record telemetry for ToU acceptance
        let acceptedExtra = GleanMetrics.Termsofuse.AcceptedExtra(
            surface: termsOfUseSurface,
            touVersion: String(termsOfUseVersion)
        )
        GleanMetrics.Termsofuse.accepted.record(acceptedExtra)
        GleanMetrics.Termsofuse.version.set(termsOfUseVersion)
        GleanMetrics.Termsofuse.date.set(Date())
    }

    private func recordImpression() {
        self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        // Record telemetry for ToU impression
        let impressionExtra = GleanMetrics.Termsofuse.ImpressionExtra(
            surface: termsOfUseSurface,
            touVersion: String(termsOfUseVersion)
        )
        GleanMetrics.Termsofuse.impression.record(impressionExtra)
    }
}
