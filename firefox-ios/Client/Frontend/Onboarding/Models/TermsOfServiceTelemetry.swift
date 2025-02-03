// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct TermsOfServiceTelemetry {
    func termsOfServiceScreenDisplayed() {
        GleanMetrics.Onboarding.termsOfServiceCard.record()
    }

    func technicalInteractionDataSwitched(to value: Bool) {
        let extra = GleanMetrics.Onboarding.ToggleTechnicalInteractionDataExtra(changedTo: value)
        GleanMetrics.Onboarding.toggleTechnicalInteractionData.record(extra)
    }

    func automaticCrashReportsSwitched(to value: Bool) {
        let extra = GleanMetrics.Onboarding.ToggleAutomaticCrashReportsExtra(changedTo: value)
        GleanMetrics.Onboarding.toggleAutomaticCrashReports.record(extra)
    }

    func termsOfServiceLinkTapped() {
        GleanMetrics.Onboarding.termsOfServiceLinkClicked.record()
    }

    func termsOfServicePrivacyNoticeLinkTapped() {
        GleanMetrics.Onboarding.termsOfServicePrivacyNoticeLinkClicked.record()
    }

    func termsOfServiceManageLinkTapped() {
        GleanMetrics.Onboarding.termsOfServiceManageLinkClicked.record()
    }

    func termsOfServiceAcceptButtonTapped() {
        GleanMetrics.Onboarding.termsOfServiceAccepted.record()
    }
}
