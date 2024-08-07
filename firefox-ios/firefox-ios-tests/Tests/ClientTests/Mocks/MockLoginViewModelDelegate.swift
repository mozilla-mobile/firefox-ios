// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockLoginViewModelDelegate: LoginViewModelDelegate {
    var loginSectionsDidUpdateCalledCount = 0
    var breachPathDidUpdateCalledCount = 0
    func loginSectionsDidUpdate() {
        loginSectionsDidUpdateCalledCount += 1
    }

    func breachPathDidUpdate() {
        breachPathDidUpdateCalledCount += 1
    }
}
