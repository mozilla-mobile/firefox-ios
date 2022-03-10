// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class TabMetadataManagerTests: XCTestCase {
    
    private var profile: MockProfile!
    private var tabManager: TabManager!

    override func setUpWithError() throws {
        super.setUp()

        profile = MockProfile(databasePrefix: "metadata_recording_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        
        profile._shutdown()
        profile = nil
        tabManager = nil
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
