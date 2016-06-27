/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class FXSnapshotTestCase: FBSnapshotTestCase {
    override func setUp() {
        super.setUp()
        if let shouldRecord = ProcessInfo.processInfo().environment["RECORD_SNAPSHOTS"] where shouldRecord == "YES" {
            recordMode = true
        }
    }
}
