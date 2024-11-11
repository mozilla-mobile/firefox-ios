// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct MicrosurveyTelemetry {
    func surveyViewed(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.ShownExtra(surveyId: surveyId)
        GleanMetrics.Microsurvey.shown.record(surveyIdExtra)
    }

    func privacyNoticeTapped(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.PrivacyNoticeTappedExtra(surveyId: surveyId)
        GleanMetrics.Microsurvey.privacyNoticeTapped.record(surveyIdExtra)
    }

    func dismissButtonTapped(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.DismissButtonTappedExtra(surveyId: surveyId)
        GleanMetrics.Microsurvey.dismissButtonTapped.record(surveyIdExtra)
    }

    func userResponseSubmitted(surveyId: String, userSelection: String) {
        let submitExtra = GleanMetrics.Microsurvey.SubmitButtonTappedExtra(surveyId: surveyId, userSelection: userSelection)
        GleanMetrics.Microsurvey.submitButtonTapped.record(submitExtra)
    }

    func confirmationShown(surveyId: String) {
        let surveyIdExtra = GleanMetrics.Microsurvey.ConfirmationShownExtra(surveyId: surveyId)
        GleanMetrics.Microsurvey.confirmationShown.record(surveyIdExtra)
    }
}
