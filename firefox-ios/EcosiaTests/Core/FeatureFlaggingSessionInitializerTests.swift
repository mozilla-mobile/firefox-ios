// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
@testable import Ecosia

class FeatureManagementSessiontInitializerTests: XCTestCase {

    func testInitializeSession() async throws {

        // given
        let initializer = FeatureManagementSessiontInitializerSPY()

        // when
        let expect = expectation(description: "The session initialization should be sent asynchronously")
        do {
            let _: DummyResponse = try await initializer.startSession()!
            XCTAssertTrue(initializer.initializeSessionRequestSent)
            expect.fulfill()
        } catch {
            XCTFail("Initializing session failed: \(error.localizedDescription)")
        }

        wait(for: [expect], timeout: 1.0)
    }
}

extension FeatureManagementSessiontInitializerTests {

    class FeatureManagementSessiontInitializerSPY: FeatureManagementSessionInitializer {

        var initializeSessionRequestSent: Bool!

        func startSession<T>() async throws -> T? where T: Decodable {
            initializeSessionRequestSent = true
            return DummyResponse(value: 0) as? T
        }
    }

    struct DummyResponse: Decodable {
        let value: Int
    }
}
