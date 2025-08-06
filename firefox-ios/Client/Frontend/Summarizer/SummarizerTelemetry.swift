// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SummarizeKit
import Common
import Shared
import Glean

class SummarizerTelemetry {
    private let gleanWrapper: GleanWrapper
    private var summarizationTimerId: GleanTimerId?

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func summarizationRequested(trigger: SummarizerTrigger) {
        let summarizationRequestedExtra = GleanMetrics.AiSummarize.SummarizationRequestedExtra(trigger: trigger.rawValue)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationRequested, extras: summarizationRequestedExtra)
    }

    func summarizationStarted(lengthWords: Int32, lengthChars: Int32) {
        let summarizationStartedExtra = GleanMetrics.AiSummarize.SummarizationStartedExtra(
            lengthChars: lengthChars,
            lengthWords: lengthWords)
        summarizationTimerStart()
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationStarted, extras: summarizationStartedExtra)
    }

    func summarizationCompleted(
        lengthChars: Int32,
        lengthWords: Int32,
        modelName: String,
        outcome: Bool,
        errorType: String? = nil
    ) {
        let summarizationCompletedExtra = GleanMetrics.AiSummarize.SummarizationCompletedExtra(
            connectionType: DeviceInfo.connectionType().rawValue,
            errorType: errorType,
            lengthChars: lengthChars,
            lengthWords: lengthWords,
            model: modelName,
            outcome: outcome)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationCompleted, extras: summarizationCompletedExtra)
    }

    func summarizationDisplayed() {
        summarizationTimerStop()
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationDisplayed)
    }

    func summarizationClosed() {
        summarizationTimerCancel()
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationClosed)
    }

    private func summarizationTimerStart() {
        summarizationTimerId = GleanMetrics.AiSummarize.summarizationTime.start()
    }

    private func summarizationTimerStop() {
        guard let timerId = summarizationTimerId else { return }
        GleanMetrics.AiSummarize.summarizationTime.stopAndAccumulate(timerId)
        // NOTE: The timer is set to nil after stopping to prevent stopping it multiple times.
        // Stopping a timer that has already been stopped can cause invalid state errors.
        // See https://github.com/mozilla-mobile/firefox-ios/issues/27669
        summarizationTimerId = nil
    }

    private func summarizationTimerCancel() {
        guard let timerId = summarizationTimerId else { return }
        GleanMetrics.AiSummarize.summarizationTime.cancel(timerId)
        // NOTE: The timer is set to nil after stopping to prevent stopping it multiple times.
        // Stopping a timer that has already been stopped can cause invalid state errors.
        // See https://github.com/mozilla-mobile/firefox-ios/issues/27669
        summarizationTimerId = nil
    }

    func summarizationConsentDisplayed(_ userAgreed: Bool) {
        let summarizationConsentDisplayedExtra =
            GleanMetrics.AiSummarize.SummarizationConsentDisplayedExtra(agreed: userAgreed)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.summarizationConsentDisplayed,
                                 extras: summarizationConsentDisplayedExtra)
    }

    func summarizationEnabled(_ summarizationEnabled: Bool) {
        GleanMetrics.UserAiSummarize.summarizationEnabled.set(summarizationEnabled)
    }

    func summarizationShakeGestureEnabled(_ shakeGestureEnabled: Bool) {
        GleanMetrics.UserAiSummarize.shakeGestureEnabled.set(shakeGestureEnabled)
    }
}
