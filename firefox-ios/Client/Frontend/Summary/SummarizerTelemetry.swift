// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Common

class SummarizerTelemetry {
    private let gleanWrapper: GleanWrapper
    private var summarizationTimerId: GleanTimerId?

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    // TODO(Issam): triggeredBy needs to be an enum
    func summarizationStarted(wordCount: Int32, triggeredBy: String) {
        let summarizeStartedExtra = GleanMetrics.AiSummarize.StartedExtra(length: wordCount, trigger: triggeredBy)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.started, extras: summarizeStartedExtra)
    }

    // TODO(Issam): outcome needs to be an enum on which we can grab some error message if not successful
    func summarizationCompleted(outcome: String, wordCount: Int32, model: String) {
        let summarizeCompletedExtra = GleanMetrics.AiSummarize.CompletedExtra(
            connectionType: DeviceInfo.connectionType().rawValue,
            length: wordCount,
            model: model,
            outcome: outcome)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.completed, extras: summarizeCompletedExtra)
    }

    func summarizationClosed() {
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.closed)
    }

    func summarizationTimerStart() {
        summarizationTimerId = GleanMetrics.AiSummarize.duration.start()
    }

    func summarizationTimerStop() {
        guard let timerId = summarizationTimerId else { return }
        GleanMetrics.AiSummarize.duration.stopAndAccumulate(timerId)
        // NOTE: The timer is set to nil after stopping to prevent stopping it multiple times.
        // Stopping a timer that has already been stopped can cause invalid state errors.
        // See https://github.com/mozilla-mobile/firefox-ios/issues/27669
        summarizationTimerId = nil
    }

    func summarizationTimerCancel() {
        guard let timerId = summarizationTimerId else { return }
        GleanMetrics.AiSummarize.duration.cancel(timerId)
        // NOTE: The timer is set to nil after stopping to prevent stopping it multiple times.
        // Stopping a timer that has already been stopped can cause invalid state errors.
        // See https://github.com/mozilla-mobile/firefox-ios/issues/27669
        summarizationTimerId = nil
    }

    func summarizationConsentDisplayed(_ userAgreed: Bool) {
        let summarizeConsentDisplayedExtra = GleanMetrics.AiSummarize.ConsentDisplayedExtra(agreed: userAgreed)
        gleanWrapper.recordEvent(for: GleanMetrics.AiSummarize.consentDisplayed, extras: summarizeConsentDisplayedExtra)
    }

    func summarizationEnabled(_ summarizationEnabled: Bool) {
        GleanMetrics.UserAiSummarize.summarizationEnabled.set(summarizationEnabled)
    }

    func summarizationShakeGestureEnabled(_ shakeGestureEnabled: Bool) {
        GleanMetrics.UserAiSummarize.shakeGestureEnabled.set(shakeGestureEnabled)
    }
}
