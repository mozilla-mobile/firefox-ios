// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Storage
import Shared
import XCTest

let blockbusterBreach = BreachRecord(
    name: "MockBreach",
    title: "A Mock Blockbuster Record",
    domain: "blockbuster.com",
    breachDate: "1970-01-02",
    description: "A mock BreachRecord for testing purposes."
)
let lipsumBreach = BreachRecord(
    name: "MockBreach",
    title: "A Mock Lorem Ipsum Record",
    domain: "lipsum.com",
    breachDate: "1970-01-02",
    description: "A mock BreachRecord for testing purposes."
)
let longBreach = BreachRecord(
    name: "MockBreach",
    title: "A Mock Swift Breach Record",
    domain: "swift.org",
    breachDate: "1970-01-02",
    description: "A mock BreachRecord for testing purposes."
)
let unbreachedLogin = LoginRecord(
    fromJSONDict: ["hostname": "http://unbreached.com", "timePasswordChanged": 1594411049000]
)
let breachedLogin = LoginRecord(
    fromJSONDict: ["hostname": "http://blockbuster.com", "timePasswordChanged": 46800000]
)

class MockBreachAlertsClient: BreachAlertsClientProtocol {
    func fetchEtag(
        endpoint: BreachAlertsClient.Endpoint,
        profile: Client.Profile,
        completion: @escaping (String?) -> Void
    ) {
        completion("33a64df551425fcc55e4d42a148795d9f25f89d4")
    }
    func fetchData(
        endpoint: BreachAlertsClient.Endpoint,
        profile: Client.Profile,
        completion: @escaping (Maybe<Data>) -> Void
    ) {
        guard let mockData = try? JSONEncoder().encode([blockbusterBreach, longBreach, lipsumBreach].self) else {
            completion(Maybe(failure: BreachAlertsError(description: "failed to encode mockRecord")))
            return
        }
        completion(Maybe(success: mockData))
    }
    var etag: String?
}

class BreachAlertsTests: XCTestCase {
    var breachAlertsManager: BreachAlertsManager!
    let unbreachedLoginSet = Set<LoginRecord>(arrayLiteral: unbreachedLogin)
    let breachedLoginSet = Set<LoginRecord>(arrayLiteral: breachedLogin)

    override func setUp() {
        super.setUp()
        self.breachAlertsManager = BreachAlertsManager(MockBreachAlertsClient(), profile: MockProfile())
    }

    override func tearDown() {
        breachAlertsManager = nil
        super.tearDown()
    }

    func testDataRequest() {
        breachAlertsManager?.loadBreaches { maybeBreaches in
            XCTAssertTrue(maybeBreaches.isSuccess)
            XCTAssertNotNil(maybeBreaches.successValue)
            if let breaches = maybeBreaches.successValue {
                XCTAssertEqual([blockbusterBreach, longBreach, lipsumBreach], breaches)
            }
        }
    }
    /* Disabled due to issue #7411 - XCTAssertNotNil failed
    func testCompareBreaches() {
        let unloadedBreachesOpt = self.breachAlertsManager?.findUserBreaches([breachedLogin])
        XCTAssertNotNil(unloadedBreachesOpt)
        if let unloadedBreaches = unloadedBreachesOpt {
            XCTAssertTrue(unloadedBreaches.isFailure)
        }

        breachAlertsManager?.loadBreaches { maybeBreachList  in
            let emptyLoginsOpt = self.breachAlertsManager?.findUserBreaches([])
            XCTAssertNotNil(emptyLoginsOpt)
            if let emptyLogins = emptyLoginsOpt {
                XCTAssertTrue(emptyLogins.isFailure)
            }

            let noBreachesOpt = self.breachAlertsManager?.findUserBreaches([unbreachedLogin])
            XCTAssertNotNil(noBreachesOpt)
            if let noBreaches = noBreachesOpt {
                XCTAssertTrue(noBreaches.isSuccess)
                XCTAssertEqual(noBreaches.successValue, Optional([]))
            }

            let breachedOpt = self.breachAlertsManager?.findUserBreaches([breachedLogin])
            XCTAssertNotNil(breachedOpt)
            if let breached = breachedOpt {
                XCTAssertTrue(breached.isSuccess)
                XCTAssertEqual(breached.successValue, [breachedLogin])
            }
        }
    }*/

    func testLoginsByHostname() {
        let unbreached = ["unbreached.com": [unbreachedLogin]]
        var result = breachAlertsManager.loginsByHostname([unbreachedLogin])
        XCTAssertEqual(result, unbreached)
        let blockbuster = ["blockbuster.com": [breachedLogin]]
        result = breachAlertsManager.loginsByHostname([breachedLogin])
        XCTAssertEqual(result, blockbuster)
    }

    func testBreachRecordForLogin() {
        breachAlertsManager.loadBreaches { _ in }
        XCTAssertEqual(blockbusterBreach, breachAlertsManager.breachRecordForLogin(breachedLogin))
    }
}
