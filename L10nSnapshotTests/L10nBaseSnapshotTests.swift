/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nBaseSnapshotTests: XCTestCase {

    var app: XCUIApplication!
    var navigator: Navigator<FxUserState>!
    var userState: FxUserState!

    var skipIntro: Bool {
        return true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app)
        app.terminate()
        var args = [LaunchArguments.ClearProfile, LaunchArguments.SkipWhatsNew]
        if skipIntro {
            args.append(LaunchArguments.SkipIntro)
        }
        springboardStart(app, args: args)

        let map = createScreenGraph(for: self, with: app)
        navigator = map.navigator()
        userState = navigator.userState

        userState.showIntro = !skipIntro

        navigator.synchronizeWithUserState()
    }

    func springboardStart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared().press(.home)
        app.launchArguments += [LaunchArguments.Test] + args
        app.activate()
    }

    func waitforExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists == true")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }

    func waitforNoExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists != true")

        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }

    func loadWebPage(url: String, waitForOtherElementWithAriaLabel ariaLabel: String) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        userState.url = url
        navigator.performAction(Action.LoadURL)
    }
}
