// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import QuickAnswersKit

final class MockQuickAnswersTelemetry: QuickAnswersTelemetry, @unchecked Sendable {
    var quickAnswersRequestedCalledCount = 0
    var recordingStartedCalledCount = 0
    var recordingCompletedCalledCount = 0
    var resultsStartedCalledCount = 0
    var resultsCompletedCalledCount = 0
    var displayedCalledCount = 0
    var citationTappedCalledCount = 0
    var closedCalledCount = 0
    var consentShownCalledCount = 0
    var permissionDeniedCalledCount = 0

    var lastRecordingOutcome: Bool?
    var lastRecordingErrorType: String?
    var lastResultsOutcome: Bool?
    var lastResultsErrorType: String?
    var lastResultsModel: String?
    var lastRequestedModel: String?
    var lastConsentAgreed: Bool?
    var lastPermissionDeniedIsTranscription: Bool?

    func quickAnswersRequested(model: String) {
        quickAnswersRequestedCalledCount += 1
        lastRequestedModel = model
    }

    func recordingStarted() {
        recordingStartedCalledCount += 1
    }

    func recordingCompleted(outcome: Bool, errorType: String?) {
        recordingCompletedCalledCount += 1
        lastRecordingOutcome = outcome
        lastRecordingErrorType = errorType
    }

    func resultsStarted() {
        resultsStartedCalledCount += 1
    }

    func resultsCompleted(outcome: Bool, errorType: String?, model: String) {
        resultsCompletedCalledCount += 1
        lastResultsOutcome = outcome
        lastResultsErrorType = errorType
        lastResultsModel = model
    }

    func permissionDenied(isTranscription: Bool) {
        permissionDeniedCalledCount += 1
        lastPermissionDeniedIsTranscription = isTranscription
    }

    func displayed() {
        displayedCalledCount += 1
    }

    func citationTapped() {
        citationTappedCalledCount += 1
    }

    func closed() {
        closedCalledCount += 1
    }

    func consentShown(agreed: Bool) {
        consentShownCalledCount += 1
        lastConsentAgreed = agreed
    }
}
