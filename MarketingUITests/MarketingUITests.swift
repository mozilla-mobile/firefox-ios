/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class MarketingSnapshotTests: XCTestCase {

    let LoadingTimeout: NSTimeInterval = 60
    let exists = NSPredicate(format: "exists = true")
    let loaded = NSPredicate(format: "value BEGINSWITH '100'")

    var sleep = false

    override func setUp() {
        super.setUp()

        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func loadWebPage(url: String, testForAutocompleteDialog: Bool = false) {
        let app = XCUIApplication()
        let addressTextField = app.textFields.elementBoundByIndex(0)
        addressTextField.tap()
        addressTextField.typeText(url)
        if testForAutocompleteDialog {
            //            for var idx:UInt = 0; idx < app.buttons.count; idx++ {
            //                let button = app.buttons.elementBoundByIndex(idx)
            //                print("\(button.identifier): \(button.value)")
            //            }
            app.buttons.elementBoundByIndex(8).tap()
        }
        let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
        expectationForPredicate(exists, evaluatedWithObject: progressIndicator, handler: nil)
        expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
        app.typeText("\n")
        waitForExpectationsWithTimeout(LoadingTimeout, handler: nil)
    }

    func testTakeMarketingScreenshots() {

        let app = XCUIApplication()

        // dismiss the intro tour
        app.buttons.elementBoundByIndex(1).tap()
        snapshot("00TopSites")

        // go to synced tabs home screen
        app.buttons.elementBoundByIndex(4).tap()
        snapshot("03SyncedTabs")

        // return to top sites
        app.buttons.elementBoundByIndex(1).tap()

        // create new tab
        app.staticTexts.firstWithName("1").tap()
        let addTabButton = app.buttons.elementBoundByIndex(3)
        addTabButton.tap()

        // load some web pages in some new tabs
        loadWebPage("http://twitter.com", testForAutocompleteDialog: true)

        app.staticTexts.firstWithName("2").tap()
        addTabButton.tap()
        loadWebPage("https://mozilla.org/firefox/desktop")

        app.staticTexts.firstWithName("3").tap()
        addTabButton.tap()
        loadWebPage("https://mozilla.org")
        app.staticTexts.firstWithName("4").tap()
        addTabButton.tap()

        loadWebPage("firefox")
        loadWebPage("https://mozilla.org/firefox/new")
        app.staticTexts.firstWithName("5").tap()
        snapshot("02TabTray")

        // return to first tab
        app.collectionViews.firstMatchingType(.Cell).tap()
        let addressTextField = app.textFields.elementBoundByIndex(0)
        addressTextField.tap()

        // perform a search but don't complete (we're testing autocomplete here)
        addressTextField.typeText("firef")
        snapshot("01SearchResults")

        // cancel search
        app.buttons.elementBoundByIndex(1).tap()
    }

}

extension XCUIElementQuery {
    func firstWithName(name: String) -> XCUIElement {
        let values = self.containingPredicate(NSPredicate(format: "label = '\(name)'"))
        if values.count > 0 {
            return values.elementBoundByIndex(0)
        }

        return self.elementBoundByIndex(0)
    }

    func firstMatchingType( type: XCUIElementType) -> XCUIElement {
        return self.childrenMatchingType(type).elementBoundByIndex(0)
    }
}
