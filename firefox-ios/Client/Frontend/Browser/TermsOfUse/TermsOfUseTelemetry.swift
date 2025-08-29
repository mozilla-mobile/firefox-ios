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
        let impressionExtra = GleanMetrics.Termsofuse.ImpressionExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.impression, extras: impressionExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.Termsofuse.impressionCount)
    }

    func termsOfUseAcceptButtonTapped(surface: Surface = .bottomSheet, acceptedDate: Date) {
        let acceptedExtra = GleanMetrics.Termsofuse.AcceptedExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.accepted, extras: acceptedExtra)
        gleanWrapper.recordQuantity(for: GleanMetrics.Termsofuse.version, value: termsOfUseVersion)
        gleanWrapper.recordDatetime(for: GleanMetrics.Termsofuse.date, value: acceptedDate)
    }

    func termsOfUseRemindMeLaterButtonTapped(surface: Surface = .bottomSheet) {
        let remindMeLaterExtra = GleanMetrics.Termsofuse.RemindMeLaterClickExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.remindMeLaterClick, extras: remindMeLaterExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.Termsofuse.remindMeLaterCount)
    }

    func termsOfUseLearnMoreButtonTapped(surface: Surface = .bottomSheet) {
        let learnMoreExtra = GleanMetrics.Termsofuse.LearnMoreClickExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.learnMoreClick, extras: learnMoreExtra)
    }

    func termsOfUsePrivacyNoticeLinkTapped(surface: Surface = .bottomSheet) {
        let privacyNoticeExtra = GleanMetrics.Termsofuse.PrivacyNoticeClickExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.privacyNoticeClick, extras: privacyNoticeExtra)
    }

    func termsOfUseTermsOfUseLinkTapped(surface: Surface = .bottomSheet) {
        let termsOfUseExtra = GleanMetrics.Termsofuse.TermsOfUseClickExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.termsOfUseClick, extras: termsOfUseExtra)
    }

    func termsOfUseDismissed(surface: Surface = .bottomSheet) {
        let dismissExtra = GleanMetrics.Termsofuse.DismissExtra(
            surface: surface.rawValue,
            touVersion: String(termsOfUseVersion)
        )
        gleanWrapper.recordEvent(for: GleanMetrics.Termsofuse.dismiss, extras: dismissExtra)
        gleanWrapper.incrementCounter(for: GleanMetrics.Termsofuse.dismissCount)
    }

    static func setUsageMetrics(gleanWrapper: GleanWrapper = DefaultGleanWrapper(),
                                profile: Profile = AppContainer.shared.resolve()) {
        let hasAcceptedTermsOfUse = profile.prefs.boolForKey(PrefsKeys.TermsOfUseAccepted) ?? false
        if hasAcceptedTermsOfUse {
            if let versionString = profile.prefs.stringForKey(PrefsKeys.TermsOfUseAcceptedVersion),
               let version = Int64(versionString) {
                gleanWrapper.recordQuantity(for: GleanMetrics.Termsofuse.version, value: version)
            }
            if let acceptedTimestamp = profile.prefs.timestampForKey(PrefsKeys.TermsOfUseAcceptedDate) {
                let acceptedDate = Date.fromTimestamp(acceptedTimestamp)
                gleanWrapper.recordDatetime(for: GleanMetrics.Termsofuse.date, value: acceptedDate)
            }
        }
    }
}
