/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public struct SyncConstants {
    // Suitable for use in dispatch_time().
    public static let SyncDelayTriggered: Int64 = 3 * Int64(NSEC_PER_SEC)
}