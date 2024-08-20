// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Client

class MockCookiesClearable: Clearable {
    var label: String { .ClearableCookies }
    var isSucceed: Success?

    func clear() -> Success {
        isSucceed = succeed()
        return succeed()
    }
}

class MockSiteDataClearable: Clearable {
    var label: String { .ClearableOfflineData }
    var isSucceed: Success?

    func clear() -> Success {
        isSucceed = succeed()
        return succeed()
    }
}
