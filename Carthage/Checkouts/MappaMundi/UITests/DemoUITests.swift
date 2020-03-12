/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import MappaMundi

class DemoUITests: XCTestCase {

    let app = XCUIApplication()
    var navigator: MMNavigator<DemoAppUserState>!
    var userState: DemoAppUserState!

    override func setUp() {
        super.setUp()

        // Create a map of the app, which we share with all tests.
        let map = createGraph(with: app, for: self)

        // Create a navigator, which we will use to navigate
        // around the app.
        navigator = map.navigator()

        // The navigator has a userState — our mental model of what is going on in the app.
        userState = navigator.userState

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app.launch()
    }

    func testRenderDotfile() {
        MMTestUtils.render(graph: createGraph(with: app, for: self))
    }

    func testSimpleNavigation() {
        navigator.performAction(Actions.addItem)
        navigator.goto(Screens.itemDetail)
        navigator.goto(Screens.itemList)

        XCTAssertEqual(Screens.itemList, navigator.screenState)

        navigator.performAction(Actions.addItem)
        XCTAssertEqual(Screens.itemList, navigator.screenState)
    }

    func testSimpleNavigationWithBack() {
        navigator.performAction(Actions.addItem)
        navigator.goto(Screens.itemDetail)
        navigator.back()

        XCTAssertEqual(Screens.itemList, navigator.screenState)
    }

    func testRecordingState() {
        navigator.performAction(Actions.addItem)
        XCTAssertEqual(1, userState.numItems)
        navigator.goto(Screens.itemDetail)
        navigator.back()
        XCTAssertEqual(1, userState.numItems)
    }

    func testNavigationWithUserStateTests() {
        navigator.performAction(Actions.addItem)
        XCTAssertEqual(1, userState.numItems)
        navigator.goto(Screens.itemDetail)
        navigator.back()

        XCTAssertEqual(Screens.itemList, navigator.screenState)
        XCTAssertEqual(1, userState.numItems)

        navigator.performAction(Actions.addItem)
        XCTAssertEqual(2, userState.numItems)

        // Enter edit mode, and then delete everything.
        navigator.performAction(Actions.deleteAllItems)
        XCTAssertEqual(0, userState.numItems)
        XCTAssertEqual(Screens.itemListEditing, navigator.screenState)
        navigator.back()

        // Go back to itemList, where we count the number of cells.
        XCTAssertEqual(Screens.itemList, navigator.screenState)
        XCTAssertEqual(0, userState.numItems)
    }

    func testConditionalEdges() {
        XCTAssertEqual(0, userState.numItems)
        XCTAssertFalse(navigator.can(goto: Screens.itemDetail))

        XCTAssertTrue(navigator.can(performAction: Actions.addItem))
        navigator.performAction(Actions.addItem)
        XCTAssertEqual(1, userState.numItems)
        XCTAssertTrue(navigator.can(goto: Screens.itemDetail))
        navigator.goto(Screens.itemDetail)

        navigator.performAction(Actions.deleteAllItems)

        XCTAssertEqual(0, userState.numItems)
        XCTAssertFalse(navigator.can(goto: Screens.itemDetail))
    }

    func testNavigatorActions() {
        XCTAssertEqual(0, userState.numItems)
        XCTAssertFalse(navigator.can(goto: Screens.itemDetail))
        navigator.performAction(Actions.addItem)
        navigator.performAction(Actions.addItem)
        XCTAssertEqual(2, userState.numItems)

        // The navigatorAction is composed of two actions by the navigator,
        // so higher level commands can be composed.
        // It is generally inferior to Swift's own method dispatch
        // except that it allows for:
        //  * the graph to be refactored
        //  * much more regular graph code.
        navigator.performAction(Actions.initialWithExactlyOne)
        XCTAssertEqual(1, userState.numItems)

        navigator.performAction(Actions.postAddItem)
        XCTAssertEqual(2, userState.numItems)
    }
}
