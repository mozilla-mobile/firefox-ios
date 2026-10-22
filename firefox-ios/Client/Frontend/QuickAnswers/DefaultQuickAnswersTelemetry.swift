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

    func quickAnswersRequested(model: QuickAnswersKit.QuickAnswersModel) {
        let extras = GleanMetrics.AiQuickAnswers.RequestedExtra(model: model.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.requested, extras: extras)
    }

    func recordingStarted(isFollowUp: Bool) {
        let extras = GleanMetrics.AiQuickAnswers.RecordingStartedExtra(isFollowUp: isFollowUp)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.recordingStarted, extras: extras)
    }

    func recordingCompleted(outcome: Bool, errorType: String?, isFollowUp: Bool) {
        let extras = GleanMetrics.AiQuickAnswers.RecordingCompletedExtra(
            errorType: errorType,
            isFollowUp: isFollowUp,
            outcome: outcome
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.recordingCompleted, extras: extras)
    }

    func resultsStarted(isFollowUp: Bool) {
        resultsTimerId = gleanWrapper.startTiming(for: GleanMetrics.AiQuickAnswers.resultsTime)
        let extras = GleanMetrics.AiQuickAnswers.ResultsStartedExtra(isFollowUp: isFollowUp)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.resultsStarted, extras: extras)
    }

    func resultsCompleted(
        outcome: Bool,
        errorType: String?,
        model: QuickAnswersKit.QuickAnswersModel,
        isFollowUp: Bool
    ) {
        if let resultsTimerId {
            gleanWrapper.stopAndAccumulateTiming(for: GleanMetrics.AiQuickAnswers.resultsTime, timerId: resultsTimerId)
            self.resultsTimerId = nil
        }
        let extras = GleanMetrics.AiQuickAnswers.ResultsCompletedExtra(
            errorType: errorType,
            isFollowUp: isFollowUp,
            model: model.rawValue,
            outcome: outcome
        )
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.resultsCompleted, extras: extras)
    }

    func permissionDenied(permission: QuickAnswersPermission) {
        let extras = GleanMetrics.AiQuickAnswers.PermissionDeniedExtra(permission: permission.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.permissionDenied, extras: extras)
    }

    func citationTapped() {
        gleanWrapper.recordEvent(for: GleanMetrics.AiQuickAnswers.citationTapped)
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
