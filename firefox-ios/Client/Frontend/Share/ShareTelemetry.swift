// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

class ShareTelemetry {
    private let gleanWrapper: GleanWrapper
    private var openURLTimerId: TimerId?

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    func sharedTo(
        activityType: UIActivity.ActivityType?,
        shareType: ShareType,
        hasShareMessage: Bool,
        isEnrolledInSentFromFirefox: Bool,
        isOptedInSentFromFirefox: Bool
    ) {
        let extra = GleanMetrics.ShareSheet.SharedToExtra(
            activityIdentifier: activityType?.rawValue ?? "unknown",
            hasShareMessage: hasShareMessage,
            isEnrolledInSentFromFirefox: isEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: isOptedInSentFromFirefox,
            shareType: shareType.typeName
        )
        gleanWrapper.recordEvent(for: GleanMetrics.ShareSheet.sharedTo, extras: extra)
    }

    // MARK: - Deeplinks

    func recordOpenURLTime() {
        openURLTimerId = gleanWrapper.startTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime)
    }

    func sendOpenURLTimeRecord() {
        guard let openURLTimerId else { return }
        gleanWrapper.stopAndAccumulateTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime,
                                             timerId: openURLTimerId)
    }

    func cancelOpenURLTimeRecord() {
        guard let openURLTimerId else { return }
        gleanWrapper.cancelTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime, timerId: openURLTimerId)
    }
}
