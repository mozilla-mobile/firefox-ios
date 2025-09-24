// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class ContextMenuScreen {
    private let app: XCUIApplication
    private let sel: ContextMenuSelectorsSet

    init(app: XCUIApplication, selectors: ContextMenuSelectorsSet = ContextMenuSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func openInPrivateTab(timeout: TimeInterval = TIMEOUT) {
        let menuTable = sel.CONTEXT_MENU_TABLE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(menuTable, timeout: timeout)

        let option = menuTable.cells.buttons[sel.OPEN_IN_PRIVATE_TAB.value]
        BaseTestCase().mozWaitForElementToExist(option, timeout: timeout)
        option.tap()
    }
}
