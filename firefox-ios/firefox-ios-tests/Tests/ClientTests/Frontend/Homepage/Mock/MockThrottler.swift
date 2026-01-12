// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Common

class MockThrottler: MainThreadThrottlerProtocol {
    private(set) var didCallThrottle = false

    init() {}

    func throttle(completion: @escaping @MainActor () -> Void) {
        didCallThrottle = true
        ensureMainThread {
            completion()
        }
    }
}
