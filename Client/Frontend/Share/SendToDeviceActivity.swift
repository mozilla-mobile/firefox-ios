// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

class SendToDeviceActivity: CustomAppActivity {
    // Send to device is only available for URL that are files
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return !url.isFile
    }

    override func prepare(withActivityItems activityItems: [Any]) {}

    override func perform() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shareSheet,
                                     value: .shareSendToDevice,
                                     extras: nil)
        activityDidFinish(true)
    }
}
