/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nSnapshotTests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchEnvironment["WIPE_PROFILE"] = "YES"
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIntro() {
        let app = XCUIApplication()

        snapshot("Intro-1")

        app.swipeLeft()
        sleep(2)
        snapshot("Intro-2")

        app.swipeLeft()
        sleep(2)
        snapshot("Intro-3")

        app.swipeLeft()
        sleep(2)
        snapshot("Intro-4")

        app.swipeLeft()
        sleep(2)
        snapshot("Intro-5")
    }
}
