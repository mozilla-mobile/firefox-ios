/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Storage
import Shared
import XCTest

let mockRecord = BreachRecord(
 name: "MockBreach",
 title: "A Mock BreachRecord",
 domain: "breached.com",
 breachDate: "1970-01-02",
 description: "A mock BreachRecord for testing purposes."
)

class MockBreachAlertsClient: BreachAlertsClientProtocol {
    func fetchData(endpoint: BreachAlertsClient.Endpoint, completion: @escaping (Maybe<Data>) -> Void) {
        guard let mockData = try? JSONEncoder().encode([mockRecord].self) else {
            completion(Maybe(failure: BreachAlertsError(description: "failed to encode mockRecord")))
            return
        }
        completion(Maybe(success: mockData))
    }
}

class BreachAlertsTests: XCTestCase {
    var breachAlertsManager: BreachAlertsManager?
    let unbreachedLogin = [
        LoginRecord(fromJSONDict: ["hostname" : "http://unbreached.com", "timePasswordChanged": 1590784648189])
    ]
    let breachedLogin = [
        LoginRecord(fromJSONDict: ["hostname" : "http://breached.com", "timePasswordChanged": 1])
   ]
    override func setUp() {
        self.breachAlertsManager = BreachAlertsManager(MockBreachAlertsClient())
    }
    /// Test for testing loadBreaches
    func testDataRequest() {
        breachAlertsManager?.loadBreaches { maybeBreaches in
            XCTAssertTrue(maybeBreaches.isSuccess)
            XCTAssertNotNil(maybeBreaches.successValue)
            if let breaches = maybeBreaches.successValue {
                XCTAssertEqual([mockRecord], breaches)
            }
        }
    }
    /// Test for testing compareBreaches
    func testCompareBreaches() {
        let unloadedBreachesOpt = self.breachAlertsManager?.compareToBreaches(breachedLogin)
        XCTAssertNotNil(unloadedBreachesOpt)
        if let unloadedBreaches = unloadedBreachesOpt {
            XCTAssertTrue(unloadedBreaches.isFailure)
        }

        breachAlertsManager?.loadBreaches { maybeBreachList  in
            let emptyLoginsOpt = self.breachAlertsManager?.compareToBreaches([])
            XCTAssertNotNil(emptyLoginsOpt)
            if let emptyLogins = emptyLoginsOpt {
                XCTAssertTrue(emptyLogins.isFailure)
            }

            let noBreachesOpt = self.breachAlertsManager?.compareToBreaches(self.unbreachedLogin)
            XCTAssertNotNil(noBreachesOpt)
            if let noBreaches = noBreachesOpt {
                XCTAssertTrue(noBreaches.isSuccess)
                XCTAssertEqual(noBreaches.successValue?.count, 0)
            }

            let breachedOpt = self.breachAlertsManager?.compareToBreaches(self.breachedLogin)
            XCTAssertNotNil(breachedOpt)
            if let breached = breachedOpt {
                XCTAssertTrue(breached.isSuccess)
                XCTAssertEqual(breached.successValue?.count, 1)
            }
        }
    }
}
