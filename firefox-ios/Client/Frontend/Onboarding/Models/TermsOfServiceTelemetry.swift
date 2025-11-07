// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct TermsOfServiceTelemetry {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func termsOfServiceScreenDisplayed() {
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.termsOfServiceCard)
    }

    func technicalInteractionDataSwitched(to value: Bool) {
        let extra = GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra(changedTo: value)
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.toggleTechnicalInteractionData, extras: extra)
    }

    func automaticCrashReportsSwitched(to value: Bool) {
        let extra = GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra(changedTo: value)
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.toggleAutomaticCrashReports, extras: extra)
    }

    func termsOfServiceLinkTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.termsOfServiceLinkClicked)
    }

    func termsOfServicePrivacyNoticeLinkTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked)
    }

    func termsOfServiceManageLinkTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.termsOfServiceManageLinkClicked)
    }

    func termsOfServiceAcceptButtonTapped(acceptedDate: Date) {
        gleanWrapper.recordEvent(for: GleanMetrics.Onboarding.termsOfServiceAccepted)
        recordDateAndVersion(acceptedDate: acceptedDate)
    }

    func recordDateAndVersion(acceptedDate: Date) {
        // Record the ToU version and date metrics with onboarding surface
        let acceptedExtra = GleanMetrics.TermsOfUse.AcceptedExtra(
            surface: TermsOfUseTelemetry.Surface.onboarding.rawValue,
            touVersion: String(TermsOfUseTelemetry().termsOfUseVersion)
        )

        gleanWrapper.recordEvent(for: GleanMetrics.TermsOfUse.accepted, extras: acceptedExtra)
        gleanWrapper.recordQuantity(
            for: GleanMetrics.UserTermsOfUse.versionAccepted,
            value: TermsOfUseTelemetry().termsOfUseVersion
        )
        gleanWrapper.recordDatetime(for: GleanMetrics.UserTermsOfUse.dateAccepted, value: acceptedDate)
    }
}
