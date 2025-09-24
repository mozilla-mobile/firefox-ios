// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UniformTypeIdentifiers

/// A special `UIActivityItemProvider` which never shares additional content, but instead records telemetry based on the
/// share activity chosen.
class ShareTelemetryActivityItemProvider: UIActivityItemProvider, @unchecked Sendable {
    private let shareTypeName: String
    private let shareMessage: ShareMessage?
    private let telemetry: ShareTelemetry

    init(
        shareTypeName: String,
        shareMessage: ShareMessage?,
        gleanWrapper: GleanWrapper = DefaultGleanWrapper()
    ) {
        self.shareTypeName = shareTypeName
        self.shareMessage = shareMessage
        self.telemetry = ShareTelemetry(gleanWrapper: gleanWrapper)

        super.init(placeholderItem: NSNull())
    }

    override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        telemetry.sharedTo(
            activityType: activityType,
            shareTypeName: shareTypeName,
            hasShareMessage: shareMessage != nil
        )

        return NSNull() // Never actually share content; we only want to record the activity type for shares
    }
}
