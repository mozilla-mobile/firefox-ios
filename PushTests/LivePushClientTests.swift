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

    func generateDeviceID() -> String {
        let num = arc4random_uniform(1 << 31)
        return "test-id-deadbeef-\(num)"
    }

    func testClientRegistration() {
        let deviceID = generateDeviceID()
        let client = PushClient(endpointURL: endpointURL)

        let registrationExpectation = XCTestExpectation()
        let unregistrationExpectation = XCTestExpectation()

        client.register(deviceID) >>== { registration in
            registrationExpectation.fulfill()
            client.unregister(registration) >>== { res in
                unregistrationExpectation.fulfill()
            }
        }

        wait(for: [registrationExpectation, unregistrationExpectation], timeout: 2 * 60)
    }

    func testClientUpdate() {
        let client = PushClient(endpointURL: endpointURL)

        let registrationExpectation = XCTestExpectation()
        let updateExpectation = XCTestExpectation()
        let unregistrationExpectation = XCTestExpectation()

        client.register(generateDeviceID()) >>== { ogRegistration in
            registrationExpectation.fulfill()

            client.updateUAID(self.generateDeviceID(), withRegistration: ogRegistration) >>== { registration in
                updateExpectation.fulfill()
                XCTAssertEqual(ogRegistration, registration)

                client.unregister(registration) >>== { res in
                    unregistrationExpectation.fulfill()
                }
            }
        }

        wait(for: [registrationExpectation, updateExpectation, unregistrationExpectation], timeout: 2 * 60)
    }
}
