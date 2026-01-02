// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@MainActor
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

    func unpinFromTopSites() {
        let unpinButton = app.buttons[StandardImageIdentifiers.Large.pinSlash]
        BaseTestCase().mozWaitForElementToExist(unpinButton)
        unpinButton.waitAndTap()
    }

    func waitForContextMenuOptions() {
        BaseTestCase().waitForElementsToExist([
            sel.OPEN_IN_NEW_TAB.element(in: app),
            sel.OPEN_IN_NEW_PRIVATE_TAB.element(in: app),
            sel.COPY_LINK.element(in: app),
            sel.DOWNLOAD_LINK.element(in: app),
            sel.SHARE_LINK.element(in: app),
            sel.BOOKMARK_LINK.element(in: app)
        ])
    }

    func tapOpenInNewTab() {
        sel.OPEN_IN_NEW_TAB.element(in: app).waitAndTap()
    }

    func tapCopyLink() {
        sel.COPY_LINK.element(in: app).waitAndTap()
    }

    func assertPrivateModeOptionsVisible() {
        BaseTestCase().mozWaitForElementToNotExist(sel.OPEN_IN_NEW_TAB.element(in: app))
        BaseTestCase().waitForElementsToExist([
            sel.OPEN_IN_NEW_PRIVATE_TAB.element(in: app),
            sel.COPY_LINK.element(in: app),
            sel.DOWNLOAD_LINK.element(in: app)
        ])
    }

    func openInNewPrivateTabAndSwitch() {
        let openPrivate = sel.OPEN_IN_NEW_PRIVATE_TAB.element(in: app)
        BaseTestCase().mozWaitForElementToExist(openPrivate)
        openPrivate.press(forDuration: 1)

        let switchBtn = sel.SWITCH_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(switchBtn)
        switchBtn.waitAndTap()
    }
}
