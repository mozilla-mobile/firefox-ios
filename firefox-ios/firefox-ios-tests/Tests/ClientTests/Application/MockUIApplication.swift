// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockUIApplication: UIApplicationInterface {
    var mockDefaultApplicationValue = false

    @available(iOS 18.2, *)
    func isDefaultApplication(for category: UIApplication.Category) throws -> Bool {
        return mockDefaultApplicationValue
    }
}
