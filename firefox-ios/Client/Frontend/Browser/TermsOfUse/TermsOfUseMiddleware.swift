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
    let telemetry: TermsOfUseTelemetry

    init(profile: Profile = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         telemetry: TermsOfUseTelemetry = TermsOfUseTelemetry()) {
        self.prefs = profile.prefs
        self.logger = logger
        self.telemetry = telemetry
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
            case TermsOfUseActionType.termsShown:
                self.recordImpression()
            case TermsOfUseActionType.termsAccepted:
                self.recordAcceptance()
            case TermsOfUseActionType.remindMeLaterTapped:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseDismissedDate)
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseRemindMeLaterTapDate)
                self.telemetry.termsOfUseRemindMeLaterButtonTapped()
            case TermsOfUseActionType.gestureDismiss:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseDismissedDate)
                self.telemetry.termsOfUseDismissed()
            case TermsOfUseActionType.learnMoreLinkTapped:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseLearnMoreTapDate)
                self.telemetry.termsOfUseLearnMoreButtonTapped()
            case TermsOfUseActionType.privacyLinkTapped:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUsePrivacyNoticeTapDate)
                self.telemetry.termsOfUsePrivacyNoticeLinkTapped()
            case TermsOfUseActionType.termsLinkTapped:
                self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseTermsLinkTapDate)
                self.telemetry.termsOfUseTermsOfUseLinkTapped()
            }
        }
    }

    private func recordAcceptance() {
        let acceptedDate = Date()
        self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseAccepted)
        self.prefs.setString(String(telemetry.termsOfUseVersion), forKey: PrefsKeys.TermsOfUseAcceptedVersion)
        self.prefs.setTimestamp(acceptedDate.toTimestamp(), forKey: PrefsKeys.TermsOfUseAcceptedDate)

        // Record telemetry for ToU acceptance
        telemetry.termsOfUseAcceptButtonTapped(surface: .bottomSheet, acceptedDate: acceptedDate)
    }

    private func recordImpression() {
        self.prefs.setBool(true, forKey: PrefsKeys.TermsOfUseFirstShown)

        // Record telemetry for ToU impression
        telemetry.termsOfUseDisplayed()
    }
}
