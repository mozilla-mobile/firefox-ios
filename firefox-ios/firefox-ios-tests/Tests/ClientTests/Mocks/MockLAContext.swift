// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import LocalAuthentication

@testable import Client

final class MockLAContext: LAContextProtocol {
    var canEvaluate = true
    var shouldSucceed = true

    func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
        return canEvaluate
    }

    func evaluatePolicy(
        _ policy: LAPolicy,
        localizedReason: String,
        reply: @escaping (Bool, Error?) -> Void
    ) {
        reply(self.shouldSucceed, self.shouldSucceed ? nil : NSError(domain: "test domain", code: -1))
    }
}
