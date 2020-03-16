/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class ScreenGraphTest: XCTestCase {
    var navigator: Navigator<TestUserState>!
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        navigator = createTestGraph(for: self, with: app).navigator()
        app.terminate()
        app.launchArguments = [LaunchArguments.Test, LaunchArguments.ClearProfile, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew]
        app.activate()
    }
}

extension ScreenGraphTest {
    func testUserStateChanges() {
        XCTAssertNil(navigator.userState.url, "Current url is empty")

        navigator.userState.url = "https://mozilla.org"
        navigator.performAction(TestActions.LoadURLByTyping)
        // The UserState is mutated in BrowserTab.
        navigator.goto(BrowserTab)

        XCTAssertTrue(navigator.userState.url?.starts(with: "www.mozilla.org") ?? false, "Current url recorded by from the url bar is \(navigator.userState.url ?? "nil")")
    }

    func testBackStack() {
        // We'll go through the browser tab, through the menu.
        navigator.goto(SettingsScreen)
        // Going back, there is no explicit way back to the browser tab,
        // and the menu will have dismissed. We should be detecting the existence of
        // elements as we go through each screen state, so if there are errors, they'll be
        // reported in the graph below.
        navigator.goto(BrowserTab)
    }

    func testSimpleToggleAction() {
        // Switch night mode on, by toggling.
        navigator.performAction(TestActions.ToggleNightMode)
        XCTAssertTrue(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTab)

        // Nothing should happen here, because night mode is already on.
        navigator.toggleOn(navigator.userState.nightMode, withAction: TestActions.ToggleNightMode)
        XCTAssertTrue(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTab)

        // Switch night mode off.
        navigator.toggleOff(navigator.userState.nightMode, withAction: TestActions.ToggleNightMode)
        XCTAssertFalse(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTab)
    }

    func testChainedActionPerf1() {
        let navigator = self.navigator!
        measure {
            navigator.userState.url = defaultURL
            navigator.performAction(TestActions.LoadURLByPasting)
            XCTAssertEqual(navigator.screenState, WebPageLoading)
        }
    }

    func testChainedActionPerf2() {
        let navigator = self.navigator!
        measure {
            navigator.userState.url = defaultURL
            navigator.performAction(TestActions.LoadURLByTyping)
            XCTAssertEqual(navigator.screenState, WebPageLoading)
        }

        navigator.userState.url = defaultURL
        navigator.performAction(TestActions.LoadURL)
        XCTAssertEqual(navigator.screenState, WebPageLoading)
    }

    func testConditionalEdgesSimple() {
        XCTAssertTrue(navigator.can(goto: PasscodeSettingsOff))
        XCTAssertFalse(navigator.can(goto: PasscodeSettingsOn))
        navigator.goto(PasscodeSettingsOff)
        XCTAssertEqual(navigator.screenState, PasscodeSettingsOff)
    }

    func testConditionalEdgesRerouting() {
        // The navigator should dynamically reroute to the target screen
        // if the userState changes.
        // This test adds to the graph a passcode setting screen. In that screen,
        // there is a noop action that fatalErrors if it is taken.
        //
        let map = createTestGraph(for: self, with: app)

        func typePasscode(_ passCode: String) {
            passCode.forEach { char in
                app.keys["\(char)"].tap()
            }
        }

        map.addScreenState(SetPasscodeScreen) { screenState in
            // This is a silly way to organize things here,
            // and is an artifical way to show that the navigator is re-routing midway through
            // a goto.
            screenState.onEnter() { userState in
                typePasscode(userState.newPasscode)
                typePasscode(userState.newPasscode)
                userState.passcode = userState.newPasscode
            }

            screenState.noop(forAction: "FatalError", transitionTo: PasscodeSettingsOn, if: "passcode == nil") { _ in fatalError() }
            screenState.noop(forAction: "Very", "Long", "Path", "Of", "Actions", transitionTo: PasscodeSettingsOn, if: "passcode != nil") { _ in }
        }

        navigator = map.navigator()

        XCTAssertTrue(navigator.can(goto: PasscodeSettingsOn))
        XCTAssertTrue(navigator.can(goto: PasscodeSettingsOff))
        XCTAssertTrue(navigator.can(goto: "FatalError"))
        navigator.goto(PasscodeSettingsOn)
        XCTAssertTrue(navigator.can(goto: PasscodeSettingsOn))
        XCTAssertFalse(navigator.can(goto: PasscodeSettingsOff))
        XCTAssertFalse(navigator.can(goto: "FatalError"))

        XCTAssertEqual(navigator.screenState, PasscodeSettingsOn)
    }
}


private let defaultURL = "https://example.com"
class TestUserState: UserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }

    var url: String? = nil
    var nightMode = false
    var passcode: String? = nil
    var newPasscode: String = "111111"
}

let PasscodeSettingsOn = "PasscodeSettingsOn"
let PasscodeSettingsOff = "PasscodeSettingsOff"
let WebPageLoading = "WebPageLoading"

fileprivate class TestActions {
    static let ToggleNightMode = "menu-NightMode"
    static let LoadURL = "LoadURL"
    static let LoadURLByTyping = "LoadURLByTyping"
    static let LoadURLByPasting = "LoadURLByPasting"
}

fileprivate func createTestGraph(for test: XCTestCase, with app: XCUIApplication) -> ScreenGraph<TestUserState> {
    let map = ScreenGraph(for: test, with: TestUserState.self)

    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab)
        screenState.tap(app.textFields["url"], to: URLBarOpen)
    }

    map.addScreenState(WebPageLoading) { screenState in
        screenState.dismissOnUse = true
        // Would like to use app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        // but this means exposing some of SnapshotHelper to another target.
        screenState.onEnterWaitFor("exists != true",
                                   element: app.progressIndicators.element(boundBy: 0))
        screenState.noop(to: BrowserTab)
    }

    map.addScreenState(BrowserTab) { screenState in
        screenState.onEnter { userState in
            userState.url = app.textFields["url"].value as? String
        }

        screenState.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
        screenState.tap(app.textFields["url"], to: URLBarOpen)

        screenState.gesture(forAction: TestActions.LoadURLByPasting, TestActions.LoadURL) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            app.textFields["url"].press(forDuration: 1.0)
            app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }
    }

    map.addScreenState(URLBarOpen) { screenState in
        screenState.gesture(forAction: TestActions.LoadURLByTyping, TestActions.LoadURL) { userState in
            let urlString = userState.url ?? defaultURL
            app.textFields["address"].typeText("\(urlString)\r")
        }
    }

    map.addScreenAction(TestActions.LoadURL, transitionTo: WebPageLoading)

    map.addScreenState(BrowserTabMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.onEnterWaitFor(element: app.tables["Context Menu"])
        screenState.tap(app.tables.cells["Settings"], to: SettingsScreen)

        screenState.tap(app.cells["menu-NightMode"], forAction: TestActions.ToggleNightMode) { userState in
            userState.nightMode = !userState.nightMode
        }

        screenState.backAction = {
            app.buttons["PhotonMenu.cancel"].tap()
        }
    }

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    map.addScreenState(SettingsScreen) { screenState in
        let table = app.tables["AppSettingsTableViewController.tableView"]
        screenState.onEnterWaitFor(element: table)

        screenState.tap(table.cells["TouchIDPasscode"], to: PasscodeSettingsOff, if: "passcode == nil")
        screenState.tap(table.cells["TouchIDPasscode"], to: PasscodeSettingsOn, if: "passcode != nil")

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(PasscodeSettingsOn) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(PasscodeSettingsOff) { screenState in
        screenState.tap(app.staticTexts["Turn Passcode On"], to: SetPasscodeScreen)
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SetPasscodeScreen) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    return map
}
