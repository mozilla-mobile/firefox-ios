/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TrackingProtectionManager {
    @Published var trackingProtectionStatus: TrackingProtectionStatus

    init(isTrackingEnabled: () -> Bool) {
        let isTrackingEnabled = isTrackingEnabled()
        self.trackingProtectionStatus = isTrackingEnabled ? .on(TPPageStats()) : .off
    }
}
