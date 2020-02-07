/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import MappaMundi
import XCTest

let serverPort = Int.random(in: 1025..<65000)

func path(forTestPage page: String) -> String {
    return "http://localhost:\(serverPort)/test-fixture/\(page)"
}

struct Base {
    static let app = XCUIApplication()
    static let helper = Helper()
}

class BaseTestCase: XCTestCase {
    // H: find a way to avoid forced unwrap
    var navigator: MMNavigator<FxUserState>!
    let app =  XCUIApplication()
    // H: find a way to avoid forced unwrap
    var userState: FxUserState!
    
    // These are used during setUp(). Change them prior to setUp() for the app to launch with different args,
    // or, use restart() to re-launch with custom args.
    var launchArguments = [LaunchArguments.ClearProfile, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.StageServer, LaunchArguments.DeviceName, "\(LaunchArguments.ServerPort)\(serverPort)"]

    func setUpScreenGraph() {
        navigator = createScreenGraph(for: self, with: app).navigator()
        userState = navigator.userState
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = [LaunchArguments.Test] + launchArguments
        app.launch()
        setUpScreenGraph()
    }

    /* H: we might need a class tearDown() to be executed once a test suite is done;
        to observe whenever a test suite starts executing and ends it's execution, there is the XCTestObservation protocol: https://developer.apple.com/documentation/xctest/xctestobservation
     */
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

}
