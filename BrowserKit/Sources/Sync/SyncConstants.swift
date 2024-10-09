// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct SyncConstants {
    // Suitable for use in dispatch_time().
    public static let SyncOnForegroundMinimumDelayMillis: UInt64 = 5 * 60 * 1000
    public static let SyncOnForegroundAfterMillis: Int64 = 10000
}
