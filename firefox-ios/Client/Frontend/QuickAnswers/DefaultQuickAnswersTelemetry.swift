// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import QuickAnswersKit

final class DefaultQuickAnswersTelemetry: QuickAnswersTelemetry {
    private let gleanWrapper: GleanWrapper
    private var resultsTimerId: GleanTimerId?

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func quickAnswersRequested() {
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.requested)
    }

    func recordingStarted() {
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.recordingStarted)
    }

    func recordingCompleted(outcome: Bool, errorType: String?) {
        let extras = GleanMetrics.AiQuickAnswers.RecordingCompletedExtra(
            errorType: errorType,
            outcome: outcome
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.recordingCompleted, extras: extras)
    }

    func resultsStarted() {
        resultsTimerId = gleanWrapper.startTiming(for: GleanMetrics.AiQuickAnswers.resultsTime)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.resultsStarted)
    }

    func resultsCompleted(outcome: Bool, errorType: String?) {
        if let resultsTimerId {
            gleanWrapper.stopAndAccumulateTiming(for: GleanMetrics.AiQuickAnswers.resultsTime, timerId: resultsTimerId)
            self.resultsTimerId = nil
        }
        let extras = GleanMetrics.AiQuickAnswers.ResultsCompletedExtra(
            errorType: errorType,
            outcome: outcome
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.resultsCompleted, extras: extras)
    }

    func closed() {
        if let resultsTimerId {
            gleanWrapper.cancelTiming(for: GleanMetrics.AiQuickAnswers.resultsTime, timerId: resultsTimerId)
            self.resultsTimerId = nil
        }
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.closed)
    }

    func consentShown(agreed: Bool) {
        let extras = GleanMetrics.AiQuickAnswers.ConsentShownExtra(agreed: agreed)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.consentShown, extras: extras)
    }
}
