/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import MappaMundi
import XCTest

struct Base {
    static let app = XCUIApplication()
    static let helper = Helper()
}

var navigator: MMNavigator<FxUserState>!
var userState: FxUserState!

class BaseTestCase: XCTestCase {

    // These are used during setUp(). Change them prior to setUp() for the app to launch with different args,
    // or, use restart() to re-launch with custom args.
    var launchArguments = [LaunchArguments.ClearProfile, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.StageServer, LaunchArguments.DeviceName, "\(LaunchArguments.ServerPort)\(serverPort)"]

    func setUpScreenGraph() {
        navigator = createScreenGraph(for: self, with: Base.app).navigator()
        userState = navigator.userState
    }

    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        Base.app.launchArguments = [LaunchArguments.Test] + launchArguments
        Base.app.launch()
        setUpScreenGraph()
    }

    override func tearDown() {
        Base.app.terminate()
        super.tearDown()
    }

}
