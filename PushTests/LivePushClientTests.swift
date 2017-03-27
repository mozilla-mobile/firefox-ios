/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Account
import Foundation
import Shared
import XCTest

class LivePushClientTests: XCTestCase {

    var endpointURL: NSURL {
        return DeveloperPushConfiguration().endpointURL
    }
    
    func testClientRegistration() {
        let num = arc4random_uniform(1 << 31)
        let deviceID = "test-id-deadbeef-\(num)"
        let client = PushClient(endpointURL: endpointURL)

        let maybeReg = client.register(deviceID).value
        XCTAssert(maybeReg.isSuccess, "Registered OK - deviceID = \(deviceID)")

        guard let registration = maybeReg.successValue else {
            return XCTFail("Registration failed – \(maybeReg.failureValue)")
        }

        let maybeVoid = client.unregister(registration).value
        XCTAssert(maybeVoid.isSuccess, "Unregistered OK - deviceID = \(deviceID), registration.uaid = \(registration.uaid)")
    }
}
