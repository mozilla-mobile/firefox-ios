// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

class ToolbarMenuTests: BaseTestCase {
	private var browserScreen: BrowserScreen!
	private var toolbarScreen: ToolbarScreen!
	private var mainMenuScreen: MainMenuScreen!
	private var webCompatReporterScreen: WebCompatReporterScreen!

	override func setUp() async throws {
		try await super.setUp()
		browserScreen = BrowserScreen(app: app)
		toolbarScreen = ToolbarScreen(app: app)
		mainMenuScreen = MainMenuScreen(app: app)
		webCompatReporterScreen = WebCompatReporterScreen(app: app)
	}

    override func tearDown() async throws {
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2306840
    // Smoketest
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

    // https://mozilla.testrail.io/index.php?/cases/view/3167601
    // Regression
    func testMainMenuPasswordsOption() {
        let loginSettingsScreen = LoginSettingsScreen(app: app)
        openMainMenu()
        mainMenuScreen.tapPasswords()
        loginSettingsScreen.tapOnboardingContinueIfShown()
        loginSettingsScreen.assertPasscodePromptShown()
        loginSettingsScreen.unlockLoginsView()
        loginSettingsScreen.waitForInitialState()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4252615
    // Regression
    func testReportBrokenSiteDismissal() {
        openReportBrokenSite()
        webCompatReporterScreen.swipeDownToDismiss()
        webCompatReporterScreen.assertIsDismissed()

        openReportBrokenSiteFromMenu()
        webCompatReporterScreen.tapClose()
        webCompatReporterScreen.assertIsDismissed()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4153018
    // Regression
    func testReportBrokenSiteURLFieldEditMode() {
        openReportBrokenSite()
        webCompatReporterScreen.assertURLFieldValue(path(forTestPage: TestPages.mozillaBook))

        // Positive control: with a valid URL and an issue type, Send Report is enabled
        webCompatReporterScreen.selectIssueType(.other)
        webCompatReporterScreen.assertSendButtonIs(enabled: true)

        webCompatReporterScreen.tapURLField()
        webCompatReporterScreen.assertURLFieldIsEditing()
        webCompatReporterScreen.replaceURL(with: "https://www.mozilla.org")
        webCompatReporterScreen.assertURLFieldValue("https://www.mozilla.org")

        webCompatReporterScreen.tapURLClearButton()
        webCompatReporterScreen.assertURLFieldIsEmpty()
        webCompatReporterScreen.commitURLEditing()
        webCompatReporterScreen.assertURLFieldIsEmpty()
        webCompatReporterScreen.assertSendButtonIs(enabled: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4153019
    // Regression
    func testReportBrokenSiteInvalidURL() {
        openReportBrokenSite()

        // Positive control: with a valid URL and an issue type, Send Report is enabled
        webCompatReporterScreen.selectIssueType(.other)
        webCompatReporterScreen.assertSendButtonIs(enabled: true)
        webCompatReporterScreen.assertURLErrorIsNotDisplayed()

        webCompatReporterScreen.tapURLField()
        webCompatReporterScreen.assertURLFieldIsEditing()
        webCompatReporterScreen.tapURLClearButton()
        webCompatReporterScreen.assertURLFieldIsEmpty()

        webCompatReporterScreen.typeURL("example..com")
        webCompatReporterScreen.commitURLEditing()
        webCompatReporterScreen.assertURLFieldValue("example..com")
        webCompatReporterScreen.assertURLErrorIsDisplayed()
        webCompatReporterScreen.assertSendButtonIs(enabled: false)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4153027
    // Regression
    func testReportBrokenSiteSiteNotUsableSubOptions() {
        validateSubOptions(of: .siteNotUsable)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4153032
    // Regression
    func testReportBrokenSiteDesignBrokenSubOptions() {
        validateSubOptions(of: .designBroken)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/4153033
    // Regression
    func testReportBrokenSiteVideoOrAudioSubOptions() {
        validateSubOptions(of: .videoOrAudio)
    }

    private func validateSubOptions(of issueType: WebCompatIssueType) {
        openReportBrokenSite()
        webCompatReporterScreen.assertSiteIssueSectionShowsPlaceholder()

        webCompatReporterScreen.selectIssueType(issueType)
        webCompatReporterScreen.assertSubOptionsDisplayed(for: issueType)
        webCompatReporterScreen.selectEachSubOption(of: issueType)
    }

    private func openReportBrokenSite() {
        navigator.openURL(path(forTestPage: TestPages.mozillaBook))
        waitUntilPageLoad()
        openReportBrokenSiteFromMenu()
    }

    private func openReportBrokenSiteFromMenu() {
        openMainMenu()
        mainMenuScreen.tapReportBrokenSite()
        webCompatReporterScreen.assertIsOpen()
    }

    private func openMainMenu() {
        toolbarScreen.tapSettingsMenuButton()
        // issue 28625: iOS 15 may not open the menu fully.
        if #unavailable(iOS 16) {
            app.swipeUp()
        }
        mainMenuScreen.assertMenuOptionsExist()
    }

	private func assertToolbarMenusAndAddressBarExist() {
		toolbarScreen.assertSettingsButtonExists()
		toolbarScreen.assertTabsButtonExists()
		toolbarScreen.assertForwardButtonExists()
		toolbarScreen.assertBackButtonExists()
		browserScreen.assertAddressBarExists()
	}
}
