// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

/// A special `UIActivityItemProvider` which never shares additional content, but instead records telemetry based on the
/// share activity chosen.
class ShareTelemetryActivityItemProvider: UIActivityItemProvider, @unchecked Sendable, FeatureFlaggable {
    private let shareType: ShareType
    private let shareMessage: ShareMessage?
    private let telemetry: ShareTelemetry

    // FXIOS-9879 For the Sent from Firefox experiment
    private var isEnrolledInSentFromFirefox: Bool {
        return featureFlags.isFeatureEnabled(.sentFromFirefox, checking: .buildOnly)
    }

    // FXIOS-9879 For the Sent from Firefox experiment
    private var isOptedInSentFromFirefox: Bool {
        return featureFlags.isFeatureEnabled(.sentFromFirefox, checking: .userOnly)
    }

    init(
        shareType: ShareType,
        shareMessage: ShareMessage?,
        telemetry: ShareTelemetry = DefaultShareTelemetry()
    ) {
        self.shareType = shareType
        self.shareMessage = shareMessage
        self.telemetry = telemetry

        super.init(placeholderItem: NSNull())
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        telemetry.sharedTo(
            activityType: activityType,
            shareType: shareType,
            hasShareMessage: shareMessage != nil,
            isEnrolledInSentFromFirefox: isEnrolledInSentFromFirefox,
            isOptedInSentFromFirefox: isOptedInSentFromFirefox
        )

        return NSNull() // Never actually share content; we only want to record the activity type for shares
    }
}
