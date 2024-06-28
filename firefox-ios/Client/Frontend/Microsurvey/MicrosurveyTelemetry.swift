// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

struct MicrosurveyTelemetry {
    func surveyViewed() {
        GleanMetrics.Microsurvey.shown.record()
    }

    func privacyNoticeTapped() {
        GleanMetrics.Microsurvey.privacyNoticeTapped.record()
    }

    func dismissButtonTapped() {
        GleanMetrics.Microsurvey.dismissButtonTapped.record()
    }

    func userResponseSubmitted(userSelection: String) {
        let userSelectionExtra = GleanMetrics.Microsurvey.SubmitButtonTappedExtra(userSelection: userSelection)
        GleanMetrics.Microsurvey.submitButtonTapped.record(userSelectionExtra)
    }

    func confirmationShown() {
        GleanMetrics.Microsurvey.confirmationShown.record()
    }
}
