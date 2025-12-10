// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Common
import Redux
import Shared

@MainActor
final class TermsOfUseMiddleware {
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
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType else { return }

        switch type {
        case TermsOfUseActionType.termsShown:
            self.recordImpression()
        case TermsOfUseActionType.termsAccepted:
            self.recordAcceptance()
        case TermsOfUseActionType.remindMeLaterTapped:
            self.incrementRemindersCount()
            self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseDismissedDate)
            self.prefs.setTimestamp(Date.now(), forKey: PrefsKeys.TermsOfUseRemindMeLaterTapDate)
            self.telemetry.termsOfUseRemindMeLaterButtonTapped()
        case TermsOfUseActionType.gestureDismiss:
            self.incrementRemindersCount()
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

    private func incrementRemindersCount() {
        // Only increment for reminders - after the first dismissal
        let hasBeenDismissedBefore = self.prefs.timestampForKey(PrefsKeys.TermsOfUseDismissedDate) != nil
        guard hasBeenDismissedBefore else { return }

        let currentCount = self.prefs.intForKey(PrefsKeys.TermsOfUseRemindersCount) ?? 0
        self.prefs.setInt(Int32(currentCount + 1), forKey: PrefsKeys.TermsOfUseRemindersCount)
    }
}
