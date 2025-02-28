// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Glean

class ShareTelemetry {
    private let gleanWrapper: GleanWrapper
    private var openURLTimerId: TimerId?
    private let logger: Logger
    private var time = 0.0

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper(), logger: Logger = DefaultLogger.shared) {
        self.gleanWrapper = gleanWrapper
        self.logger = logger
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

    func recordOpenDeeplinkTime() {
        openURLTimerId = gleanWrapper.startTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime)
        time = CACurrentMediaTime()
    }

    func sendOpenDeeplinkTimeRecord() {
        guard let openURLTimerId else { return }
        gleanWrapper.stopAndAccumulateTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime,
                                             timerId: openURLTimerId)
        time = CACurrentMediaTime() - time
        logger.log("Startup time handling deeplink took \"\(time)\" seconds", level: .debug, category: .lifecycle)
    }

    func cancelOpenURLTimeRecord() {
        guard let openURLTimerId else { return }
        gleanWrapper.cancelTiming(for: GleanMetrics.Share.deeplinkOpenUrlStartupTime, timerId: openURLTimerId)
    }
}
