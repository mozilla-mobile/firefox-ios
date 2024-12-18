// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MappaMundi
import XCTest
import Common
import Shared

class ScreenGraphTest: XCTestCase {
    var navigator: MMNavigator<TestUserState>!
    var app: XCUIApplication!

    func mozWaitForElementToNotExist(_ element: XCUIElement, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()

        while element.exists {
            if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for element \(element) to not exist")
                break
            }
            usleep(10000)
        }
    }

    func waitUntilPageLoad() {
        let app = XCUIApplication()
        let progressIndicator = app.progressIndicators.element(boundBy: 0)

        mozWaitForElementToNotExist(progressIndicator, timeout: 90.0)
    }

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createTestGraph(for: self, with: app).navigator()
        app.terminate()
        app.launchArguments = [LaunchArguments.Test,
                               LaunchArguments.ClearProfile,
                               LaunchArguments.SkipIntro,
                               LaunchArguments.SkipWhatsNew,
                               LaunchArguments.SkipETPCoverSheet,
                               LaunchArguments.SkipContextualHints,
                               LaunchArguments.DisableAnimations]
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
    func testUserStateChanges() {
        XCTAssertNil(navigator.userState.url, "Current url is empty")

        navigator.userState.url = "https://mozilla.org"
        navigator.performAction(TestActions.LoadURLByTyping)
        waitUntilPageLoad()
        // The UserState is mutated in BrowserTab.
        navigator.goto(BrowserTab)
        navigator.nowAt(BrowserTab)
        let currentURL = navigator.userState.url as String?
        XCTAssertTrue(currentURL?.starts(with: "mozilla.org") ?? false, "Current url recorded by from the url bar is \(currentURL ?? "nil")")
    }

    func testSimpleToggleAction() {
        navigator.userState.url = "https://mozilla.org"
        navigator.performAction(TestActions.LoadURLByTyping)
        waitUntilPageLoad()
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
        navigator.toggleOff(navigator.userState.nightMode, withAction: TestActions.ToggleNighModeOff)
        XCTAssertFalse(navigator.userState.nightMode)
        XCTAssertEqual(navigator.screenState, BrowserTabMenu)
    }
}

private let defaultURL = "https://example.com"

@objcMembers
class TestUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }

    var url: String?
    var nightMode = false
    var passcode: String?
    var newPasscode: String = "111111"
}

let WebPageLoading = "WebPageLoading"

private class TestActions {
    static let ToggleNightMode = StandardImageIdentifiers.Large.nightMode
    static let ToggleNighModeOff = "MainMenu.NightModeOn"
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

private func createTestGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<TestUserState> {
    let map = MMScreenGraph(for: test, with: TestUserState.self)

    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab)
        screenState.tap(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], to: URLBarOpen)
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
            userState.url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].value as? String
        }

        screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], to: BrowserTabMenu)
        screenState.tap(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], to: URLBarOpen)

        screenState.gesture(forAction: TestActions.LoadURLByPasting, TestActions.LoadURL) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].press(forDuration: 1.0)
            app.tables["Context Menu"].cells[AccessibilityIdentifiers.Photon.pasteAndGoAction].tap()
        }
    }

    map.addScreenState(URLBarOpen) { screenState in
        screenState.gesture(forAction: TestActions.LoadURLByTyping, TestActions.LoadURL) { userState in
            let urlString = userState.url ?? defaultURL
            app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].typeText("\(urlString)\r")
        }
    }

    map.addScreenAction(TestActions.LoadURL, transitionTo: WebPageLoading)

    map.addScreenState(ToolsBrowserTabMenu) { screenState in
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.nightMode],
            forAction: TestActions.ToggleNightMode,
            transitionTo: BrowserTabMenu
        ) { userState in
            userState.nightMode = !userState.nightMode
        }

        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.nightMode],
            forAction: TestActions.ToggleNighModeOff,
            transitionTo: BrowserTabMenu
        ) { userState in
            userState.nightMode = !userState.nightMode
        }
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.tap(app.tables.cells["Settings"], to: SettingsScreen)
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.tools], to: ToolsBrowserTabMenu)

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
