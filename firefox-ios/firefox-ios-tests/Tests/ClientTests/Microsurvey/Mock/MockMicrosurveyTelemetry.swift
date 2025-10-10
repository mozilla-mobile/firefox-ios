// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

final class MockMicrosurveyTelemetry: MicrosurveyTelemetryProtocol {
    var surveyViewedCalledCount = 0
    var privacyNoticeTappedCalledCount = 0
    var dismissButtonTappedCalledCount = 0
    var userResponseSubmittedCalledCount = 0
    var confirmationShownCalledCount = 0

    // Saves only the last captured argument, can be expanded as needed
    var lastSurveyId: String?
    var lastUserSelection: String?

    func surveyViewed(surveyId: String) {
        surveyViewedCalledCount += 1
        lastSurveyId = surveyId
    }

    func privacyNoticeTapped(surveyId: String) {
        privacyNoticeTappedCalledCount += 1
        lastSurveyId = surveyId
    }

    func dismissButtonTapped(surveyId: String) {
        dismissButtonTappedCalledCount += 1
        lastSurveyId = surveyId
    }

    func userResponseSubmitted(surveyId: String, userSelection: String) {
        userResponseSubmittedCalledCount += 1
        lastSurveyId = surveyId
        lastUserSelection = userSelection
    }

    func confirmationShown(surveyId: String) {
        confirmationShownCalledCount += 1
        lastSurveyId = surveyId
    }
}
