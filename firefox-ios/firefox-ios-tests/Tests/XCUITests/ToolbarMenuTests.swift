// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class ToolbarMenuTests: BaseTestCase {
	private var browserScreen: BrowserScreen!
	private var toolbarScreen: ToolbarScreen!
	private var mainMenuScreen: MainMenuScreen!

	override func setUp() async throws {
		try await super.setUp()
		browserScreen = BrowserScreen(app: app)
		toolbarScreen = ToolbarScreen(app: app)
		mainMenuScreen = MainMenuScreen(app: app)
	}

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306840
    func testToolbarMenu() {
        let hamburgerMenu = toolbarScreen.getToolbarSettingsMenuButtonElement()
        let tabsButton = toolbarScreen.getTabsButtonElement()
        let forwardButton = toolbarScreen.getForwardButtonElement()
		assertToolbarMenusAndAddressBarExist()
		XCTAssertTrue(
            hamburgerMenu.isLeftOf(rightElement: tabsButton),
            "Menu button is not on the left side of tabs button"
        )
        XCTAssertTrue(
            hamburgerMenu.isRightOf(rightElement: forwardButton),
            "Menu button is not below the pocket cells area"
        )

		toolbarScreen.tapSettingsMenuButton()
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            app.swipeUp()
        }
		mainMenuScreen.assertMenuOptionsExist()

        // issue 28629: menu not available in landscape mode (iOS 15 only)
        if #available(iOS 16, *) {
			mainMenuScreen.dismissMenu()
            XCUIDevice.shared.orientation = .landscapeLeft
			assertToolbarMenusAndAddressBarExist()
            XCTAssertTrue(
                hamburgerMenu.isLeftOf(rightElement: tabsButton),
                "Menu button is not on the left side of tabs button"
            )
            XCTAssertTrue(
                hamburgerMenu.isRightOf(rightElement: forwardButton),
                "Menu button is not below the pocket cells area"
            )

			toolbarScreen.tapSettingsMenuButton()
			mainMenuScreen.assertMenuOptionsExist()

			mainMenuScreen.dismissMenu()
			mainMenuScreen.assertMenuIsDismissed()
        }
    }

	private func assertToolbarMenusAndAddressBarExist() {
		toolbarScreen.assertSettingsButtonExists()
		toolbarScreen.assertTabsButtonExists()
		toolbarScreen.assertForwardButtonExists()
		toolbarScreen.assertBackButtonExists()
		browserScreen.assertAddressBarExists()
	}
}
