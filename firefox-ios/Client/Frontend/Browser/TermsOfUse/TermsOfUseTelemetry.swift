// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Glean

struct TermsOfUseTelemetry {
    enum Surface: String {
        case bottomSheet = "bottom_sheet"
        case onboarding = "onboarding"
    }

    private let gleanWrapper: GleanWrapper
    let termsOfUseVersion: Int64 = 4

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func termsOfUseDisplayed(surface: Surface = .bottomSheet) {
        let shownExtra = GleanMetrics.TermsOfUse.ShownExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.shown, extras: shownExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.UserTermsOfUse.shownCount)
    }

    func termsOfUseAcceptButtonTapped(surface: Surface = .bottomSheet, acceptedDate: Date) {
        let acceptedExtra = GleanMetrics.TermsOfUse.AcceptedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.accepted, extras: acceptedExtra)
        gleanWrapper.recordQuantity(for: GleanMetrics.UserTermsOfUse.versionAccepted, value: termsOfUseVersion)
        gleanWrapper.recordDatetime(for: GleanMetrics.UserTermsOfUse.dateAccepted, value: acceptedDate)
    }

    func termsOfUseRemindMeLaterButtonTapped(surface: Surface = .bottomSheet) {
        let remindMeLaterExtra = GleanMetrics.TermsOfUse.RemindMeLaterButtonTappedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.remindMeLaterButtonTapped, extras: remindMeLaterExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.UserTermsOfUse.remindMeLaterCount)
    }

    func termsOfUseLearnMoreButtonTapped(surface: Surface = .bottomSheet) {
        let learnMoreExtra = GleanMetrics.TermsOfUse.LearnMoreButtonTappedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.learnMoreButtonTapped, extras: learnMoreExtra)
    }

    func termsOfUsePrivacyNoticeLinkTapped(surface: Surface = .bottomSheet) {
        let privacyNoticeExtra = GleanMetrics.TermsOfUse.PrivacyNoticeTappedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.privacyNoticeTapped, extras: privacyNoticeExtra)
    }

    func termsOfUseTermsOfUseLinkTapped(surface: Surface = .bottomSheet) {
        let termsOfUseExtra = GleanMetrics.TermsOfUse.TermsOfUseLinkTappedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.termsOfUseLinkTapped, extras: termsOfUseExtra)
    }

    func termsOfUseDismissed(surface: Surface = .bottomSheet) {
        let dismissExtra = GleanMetrics.TermsOfUse.DismissedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.dismissed, extras: dismissExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.UserTermsOfUse.dismissedCount)
    }

    static func setUsageMetrics(gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
                                profile: Profile = AppContainer.shared.resolve()) {
        let hasAcceptedTermsOfUse = profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        let hasAcceptedTermsOfService = profile.prefs.intForKey(PrefsKeys.TermsOfServiceAccepted) == 1

        if hasAcceptedTermsOfUse || hasAcceptedTermsOfService {
            let datePref = hasAcceptedTermsOfUse ? PrefsKeys.TermsOfUseAcceptedDate : PrefsKeys.TermsOfServiceAcceptedDate
            if let acceptedTimestamp = profile.prefs.timestampForKey(datePref) {
                let acceptedDate = Date.fromTimestamp(acceptedTimestamp)
                gleanWrapper.recordDatetime(for: GleanMetrics.UserTermsOfUse.dateAccepted, value: acceptedDate)
            }

            let versionPref = hasAcceptedTermsOfUse ? PrefsKeys.TermsOfUseAcceptedVersion :
                PrefsKeys.TermsOfServiceAcceptedVersion
            if let versionString = profile.prefs.stringForKey(versionPref),
               let version = Int64(versionString) {
                gleanWrapper.recordQuantity(for: GleanMetrics.UserTermsOfUse.versionAccepted, value: version)
            }
        }
    }
}
