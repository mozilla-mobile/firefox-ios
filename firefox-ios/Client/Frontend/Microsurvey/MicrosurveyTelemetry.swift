// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol MicrosurveyTelemetryProtocol {
    func surveyViewed(surveyId: String)
    func privacyNoticeTapped(surveyId: String)
    func dismissButtonTapped(surveyId: String)
    func userResponseSubmitted(surveyId: String, userSelection: String)
    func confirmationShown(surveyId: String)
}

struct MicrosurveyTelemetry: MicrosurveyTelemetryProtocol {
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func surveyViewed(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.ShownExtra(surveyId: surveyId)
        gleanWrapper.recordEvent(for: GleanMetrics.Microsurvey.shown, extras: surveyIdExtra)
    }

    func privacyNoticeTapped(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.PrivacyNoticeTappedExtra(surveyId: surveyId)
        gleanWrapper.recordEvent(for: GleanMetrics.Microsurvey.privacyNoticeTapped, extras: surveyIdExtra)
    }

    func dismissButtonTapped(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.DismissButtonTappedExtra(surveyId: surveyId)
        gleanWrapper.recordEvent(for: GleanMetrics.Microsurvey.dismissButtonTapped, extras: surveyIdExtra)
    }

    func userResponseSubmitted(surveyId: String, userSelection: String) {
        let submitExtra = GleanMetrics.Microsurvey.SubmitButtonTappedExtra(surveyId: surveyId, userSelection: userSelection)
        gleanWrapper.recordEvent(for: GleanMetrics.Microsurvey.submitButtonTapped, extras: submitExtra)
    }

    func confirmationShown(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.ConfirmationShownExtra(surveyId: surveyId)
        gleanWrapper.recordEvent(for: GleanMetrics.Microsurvey.confirmationShown, extras: surveyIdExtra)
    }
}
