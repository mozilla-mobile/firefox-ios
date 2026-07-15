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

    var lastRecordingOutcome: Bool?
    var lastRecordingErrorType: String?
    var lastResultsOutcome: Bool?
    var lastResultsErrorType: String?
    var lastConsentAgreed: Bool?

    func quickAnswersRequested() {
        quickAnswersRequestedCalledCount += 1
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

    func resultsCompleted(outcome: Bool, errorType: String?) {
        resultsCompletedCalledCount += 1
        lastResultsOutcome = outcome
        lastResultsErrorType = errorType
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
