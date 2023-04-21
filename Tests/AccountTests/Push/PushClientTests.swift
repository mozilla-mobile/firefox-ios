// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Account
import Foundation
import Shared
import XCTest

class PushClientTests: XCTestCase {
    var endpointURL: NSURL {
        return FennecPushConfiguration().endpointURL
    }

    func generateDeviceID() -> String {
        let num = arc4random_uniform(1 << 31)
        return "test-id-deadbeef-\(num)"
    }

    func testClientRegistration() {
        let deviceID = generateDeviceID()
        let client = PushClientImplementation(endpointURL: endpointURL,
                                              pushRegistrationAPI: PushRegistrationAPIMock())

        let registrationExpectation = XCTestExpectation()
        let unregistrationExpectation = XCTestExpectation()

        client.register(deviceID) { registration in
            registrationExpectation.fulfill()
            guard let registration = registration else {
                XCTFail("Registration should be present")
                return
            }

            client.unregister(registration) {
                unregistrationExpectation.fulfill()
            }
        }

        wait(for: [registrationExpectation, unregistrationExpectation], timeout: 0.1)
    }
}

// MARK: PushRegistrationAPIMock
class PushRegistrationAPIMock: PushRegistrationAPI {
    func fetchPushRegistration(request: URLRequest, completion: @escaping (PushRegistrationResult?) -> Void) {
        completion(.success(PushRegistration(uaid: UUID().uuidString, secret: UUID().uuidString)))
    }

    func executeRequest(_ request: URLRequest, completion: @escaping () -> Void) {
        completion()
    }
}
