// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import MappaMundi
import XCTest

class ScreenGraphTest: XCTestCase {
    var navigator: MMNavigator<TestUserState>!
    var app: XCUIApplication!

    override func setUp() {
        app = XCUIApplication()
        navigator = createTestGraph(for: self, with: app).navigator()
        app.terminate()
        app.launchArguments = [LaunchArguments.Test, LaunchArguments.ClearProfile, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.SkipContextualHintJumpBackIn]
        app.activate()
    }
}

extension XCTestCase {
    func wait(forElement element: XCUIElement, timeout: TimeInterval) {
        let predicate = NSPredicate(format: "exists == 1")
        expectation(for: predicate, evaluatedWith: element)
        waitForExpectations(timeout: timeout)
    }
}

extension ScreenGraphTest {
    // Temoporary disable since it is failing intermittently on BB
    func testUserStateChanges() {
        XCTAssertNil(navigator.userState.url, "Current url is empty")

        navigator.userState.url = "https://mozilla.org"
        navigator.performAction(TestActions.LoadURLByTyping)
        // The UserState is mutated in BrowserTab.
        navigator.goto(BrowserTab)
        navigator.nowAt(BrowserTab)
        XCTAssertTrue(navigator.userState.url?.starts(with: "www.mozilla.org") ?? false, "Current url recorded by from the url bar is \(navigator.userState.url ?? "nil")")
    }

    func testBackStack() {
        wait(forElement: app.buttons["urlBar-cancel"], timeout: 5)
        app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(BrowserTab)
        // We'll go through the browser tab, through the menu.
        navigator.goto(SettingsScreen)
        // Going back, there is no explicit way back to the browser tab,
        // and the menu will have dismissed. We should be detecting the existence of
        // elements as we go through each screen state, so if there are errors, they'll be
        // reported in the graph below.
        navigator.goto(BrowserTab)
    }

    func testSimpleToggleAction() {
        wait(forElement: app.buttons["urlBar-cancel"], timeout: 5)
        app.buttons["urlBar-cancel"].tap()
        navigator.nowAt(BrowserTab)
        // Switch night mode on, by toggling.
        navigator.performAction(TestActions.ToggleNightMode)
        XCTAssertTrue(navigator.userState.nightMode)

        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        XCTAssertEqual(navigator.screenState, BrowserTabMenu)

        // Nothing should happen here, because night mode is already on.
        navigator.toggleOn(navigator.userState.nightMode, withAction: TestActions.ToggleNightMode)
        XCTAssertTrue(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTabMenu)
        
        
        navigator.nowAt(BrowserTabMenu)
        // Switch night mode off.
        navigator.toggleOff(navigator.userState.nightMode, withAction: TestActions.ToggleNightMode)
        XCTAssertFalse(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTabMenu)
    }

    func testChainedActionPerf1() throws {
        throw XCTSkip("Skipping this test due intermittent failures")
        let navigator = self.navigator!
        measure {
            navigator.userState.url = defaultURL
            wait(forElement: app.textFields.firstMatch, timeout: 3)
            navigator.performAction(TestActions.LoadURLByPasting)
            XCTAssertEqual(navigator.screenState, WebPageLoading)
        }
    }

    func testChainedActionPerf2() throws {
        throw XCTSkip("Skipping this test due intermittent failures")
        let navigator = self.navigator!
        measure {
            navigator.userState.url = defaultURL
            navigator.performAction(TestActions.LoadURLByPasting)
            XCTAssertEqual(navigator.screenState, WebPageLoading)
        }

        navigator.userState.url = defaultURL
        navigator.performAction(TestActions.LoadURL)
        XCTAssertEqual(navigator.screenState, WebPageLoading)
    }
}


private let defaultURL = "https://example.com"

@objcMembers
class TestUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }

    var url: String? = nil
    var nightMode = false
    var passcode: String? = nil
    var newPasscode: String = "111111"
}

let WebPageLoading = "WebPageLoading"

fileprivate class TestActions {
    static let ToggleNightMode = "menu-NightMode"
    static let LoadURL = "LoadURL"
    static let LoadURLByTyping = "LoadURLByTyping"
    static let LoadURLByPasting = "LoadURLByPasting"
}

public var isTablet: Bool {
    // There is more value in a variable having the same name,
    // so it can be used in both predicates and in code
    // than avoiding the duplication of one line of code.
    return UIDevice.current.userInterfaceIdiom == .pad
}

fileprivate func createTestGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<TestUserState> {
    let map = MMScreenGraph(for: test, with: TestUserState.self)

    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab)
        screenState.tap(app.textFields["url"], to: URLBarOpen)
    }

    map.addScreenState(WebPageLoading) { screenState in
        screenState.dismissOnUse = true
        // Would like to use app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        // but this means exposing some of SnapshotHelper to another target.
        // screenState.onEnterWaitFor("exists != true",
                                   // element: app.progressIndicators.element(boundBy: 0))
        screenState.noop(to: BrowserTab)
    }

    map.addScreenState(BrowserTab) { screenState in
        screenState.onEnter { userState in
            userState.url = app.textFields["url"].value as? String
        }

        screenState.tap(app.buttons[AccessibilityIdentifiers.BottomToolbar.settingsMenuButton], to: BrowserTabMenu)
        screenState.tap(app.textFields["url"], to: URLBarOpen)

        screenState.gesture(forAction: TestActions.LoadURLByPasting, TestActions.LoadURL) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            app.textFields["url"].press(forDuration: 1.0)
            app.tables["Context Menu"].cells["menu-PasteAndGo"].tap()
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
        screenState.tap(app.tables.cells["Settings"], to: SettingsScreen)

        screenState.tap(app.cells["menu-NightMode"], forAction: TestActions.ToggleNightMode, transitionTo: BrowserTabMenu) { userState in
            userState.nightMode = !userState.nightMode
        }

        screenState.backAction = {
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].tap()
            } else {
                app.buttons["PhotonMenu.close"].tap()
            }
        }
    }

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    map.addScreenState(SettingsScreen) { screenState in
        let table = app.tables[AccessibilityIdentifiers.Settings.tableViewController]
        screenState.onEnterWaitFor(element: table)

        screenState.backAction = navigationControllerBackAction
    }

    return map
}
