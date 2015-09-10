/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Breakpad

public protocol CrashReporter {
    func start(onCurrentThread: Bool)
    func stop()
    func addUploadParameter(value: String!, forKey: String!)
    func setUploadingEnabled(enabled: Bool)
}

/**
*  A simple wrapper around the BreakpadController instance to allow us to create mocks for testing
*/
struct BreakpadCrashReporter: CrashReporter {
    let breakpadInstance: BreakpadController

    func start(onCurrentThread: Bool) {
        breakpadInstance.start(onCurrentThread)
    }

    func stop() {
        breakpadInstance.stop()
    }

    func addUploadParameter(value: String!, forKey: String!) {
        breakpadInstance.addUploadParameter(value, forKey: forKey)
    }

    func setUploadingEnabled(enabled: Bool) {
        breakpadInstance.setUploadingEnabled(enabled)
    }
}
