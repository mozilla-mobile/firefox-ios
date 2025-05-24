// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class MockApplication: Application {
    var openCalled = 0
    var canOpenCalled = 0
    var canOpenURL = true

    func open(url: URL) {
        openCalled += 1
    }

    func canOpen(url: URL) -> Bool {
        canOpenCalled += 1
        return canOpenURL
    }
}
