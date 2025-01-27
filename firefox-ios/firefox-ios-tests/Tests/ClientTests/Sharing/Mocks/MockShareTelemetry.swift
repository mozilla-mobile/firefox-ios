// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockShareTelemetry: ShareTelemetry {
    var activityType: UIActivity.ActivityType?
    var shareType: ShareType?
    var hasShareMessage: Bool?
    var isEnrolledInSentFromFirefox: Bool?
    var isOptedInSentFromFirefox: Bool?

    var sharedToCalled = 0

    func sharedTo(
        activityType: UIActivity.ActivityType?,
        shareType: ShareType,
        hasShareMessage: Bool,
        isEnrolledInSentFromFirefox: Bool,
        isOptedInSentFromFirefox: Bool
    ) {
        self.activityType = activityType
        self.shareType = shareType
        self.hasShareMessage = hasShareMessage
        self.isEnrolledInSentFromFirefox = isEnrolledInSentFromFirefox
        self.isOptedInSentFromFirefox = isOptedInSentFromFirefox

        sharedToCalled += 1
    }
}
