// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class HomePageScreen {
    private let app: XCUIApplication
    private let sel: HomePageSelectorsSet

    private var collection: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }

    init(app: XCUIApplication, selectors: HomePageSelectorsSet = HomePageSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func swipeToCustomizeHomeOption() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            BaseTestCase().mozWaitForElementToExist(collection)
            collection.swipeUp()
            collection.swipeUp()
        }
    }
}
