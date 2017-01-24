//
//  PushClientTests.swift
//  Client
//
//  Created by James Hugman on 1/18/17.
//  Copyright © 2017 Mozilla. All rights reserved.
//

@testable import Client
import Foundation
import Shared
import XCTest

private let timeoutPeriod: NSTimeInterval = 600

class PushClientTests: XCTestCase {

    var endpointURL: NSURL {
        return DeveloperPushConfiguration().endpointURL
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExistence() {
        let expectation = expectationWithDescription(#function)
        let deviceID = "test-id-deadbeef"
        let client = PushClient(endpointURL: endpointURL)

        client.registerUAID(deviceID) >>== { registration in
            print("Registered: \(registration.uaid)")
            client.unregister(registration)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(timeoutPeriod, handler: nil)
    }
    
}
