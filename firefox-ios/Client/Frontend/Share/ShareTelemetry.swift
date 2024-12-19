// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

protocol ShareTelemetry {
    func sharedTo(
        activityType: UIActivity.ActivityType?,
        shareType: ShareType,
        hasShareMessage: Bool,
        isEnrolledInSentFromFirefox: Bool,
        isOptedInSentFromFirefox: Bool
    )
}

struct DefaultShareTelemetry: ShareTelemetry {
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
        GleanMetrics.ShareSheet.sharedTo.record(extra)
    }
}
