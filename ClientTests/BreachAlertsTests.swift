//
//  BreachAlertsTests.swift
//  ClientTests
//
//  Created by Vanna Phong on 5/29/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//
@testable import Client
import Shared
import XCTest

let mockRecord = BreachRecord(
 name: "MockBreach",
 title: "A Mock BreachRecord",
 domain: "foo.bar",
 breachDate: "0000-01-01",
 description: "A mock BreachRecord for testing purposes."
)

class MockBreachAlertsClient: BreachAlertsClientProtocol {
    func fetchData(endpoint: BreachAlertsClient.Endpoint, completion: @escaping (Maybe<Data>) -> Void) {
        guard let mockData = try? JSONEncoder().encode(mockRecord.self) else {
            completion(Maybe(failure: BreachAlertsError(description: "failed to encode mockRecord")))
            return
        }
        completion(Maybe(success: mockData))
    }
}

class BreachAlertsTests: XCTestCase {
    var breachAlertsManager: BreachAlertsManager?

    override func setUp() {
        self.breachAlertsManager = BreachAlertsManager(MockBreachAlertsClient())
    }
    /// Test for testing loadBreaches
    func testDataRequest() {
        breachAlertsManager?.loadBreaches { maybeBreaches in
            // Verify data in breach alerts manager is parsing correctly and that you can interact with objects
            // test that specific variables are present etc
            XCTAssertTrue(type(of: maybeBreaches) == Maybe<[BreachRecord]>.Type.self)
            XCTAssertTrue(maybeBreaches.isSuccess)
            XCTAssertTrue(maybeBreaches.successValue != nil)
            if let breaches = maybeBreaches.successValue {
                XCTAssertTrue(type(of: breaches) == [BreachRecord]?.self)
                XCTAssertTrue([mockRecord] == breaches)
            }
        }
    }

}
