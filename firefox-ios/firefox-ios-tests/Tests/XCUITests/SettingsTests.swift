// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class SettingsTests: BaseTestCase {
    override func tearDown() {
        if name.contains("testAutofillPasswordSettingsOptionSubtitles") ||
            name.contains("testBrowsingSettingsOptionSubtitles") ||
            name.contains("testSettingsOptionSubtitlesDarkMode") ||
            name.contains("testSettingsOptionSubtitlesDarkModeLandscape") {
            switchThemeToDarkOrLight(theme: "Light")
        }
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    private func checkShowImages(showImages: Bool = true) {
        let noImageStatusMode = app.otherElements.tables.cells.switches["NoImageModeStatus"]
        mozWaitForElementToExist(noImageStatusMode)
        if showImages {
            XCTAssertEqual(noImageStatusMode.value as? String, "0")
        } else {
            XCTAssertEqual(noImageStatusMode.value as? String, "1")
        }
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2334757
    func testHelpOpensSUMOInTab() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let settingsTableView = app.tables[AccessibilityIdentifiers.Settings.tableViewController]

        while settingsTableView.staticTexts["Help"].exists == false {
            settingsTableView.swipeUp()
        }
        let helpMenu = settingsTableView.cells["Help"]
        XCTAssertTrue(helpMenu.isEnabled)
        helpMenu.waitAndTap()

        waitUntilPageLoad()
        let url = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForValueContains(url, value: "support.mozilla.org")
        mozWaitForElementToExist(app.webViews.staticTexts["Firefox for iOS Support"])

        let numTabs = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].value
        XCTAssertEqual("2", numTabs as? String, "Sume should be open in a different tab")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2334760
    func testOpenSiriOption() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.performAction(Action.OpenSiriFromSettings)
        mozWaitForElementToExist(app.cells["SiriSettings"])
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2334756
    func testCopiedLinks() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(BrowsingSettings)

        // For iOS 15, we must scroll until the switch is visible.
        if #unavailable(iOS 16) {
            app.swipeUp()
            mozWaitForElementToExist(app.tables.cells.switches["Offer to Open Copied Links, When opening Firefox"])
        }
        // Check Offer to open copied links, when opening firefox is off
        let value = app.tables.cells.switches["Offer to Open Copied Links, When opening Firefox"].value
        XCTAssertEqual(value as? String, "0")

        // Switch on, Offer to open copied links, when opening firefox
        app.tables.cells.switches["Offer to Open Copied Links, When opening Firefox"].waitAndTap()

        // Check Offer to open copied links, when opening firefox is on
        let value2 = app.tables.cells.switches["Offer to Open Copied Links, When opening Firefox"].value
        XCTAssertEqual(value2 as? String, "1")

        navigator.nowAt(BrowsingSettings)
        navigator.goto(NewTabScreen)
        navigator.goto(BrowsingSettings)

        // Check Offer to open copied links, when opening firefox is on
        let value3 = app.tables.cells.switches["Offer to Open Copied Links, When opening Firefox"].value
        XCTAssertEqual(value3 as? String, "1")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307041
    func testOpenMailAppSettings() {
        waitForTabsButton()
        navigator.nowAt(NewTabScreen)
        navigator.goto(MailAppSettings)

        // Check that the list is shown
        mozWaitForElementToExist(app.tables["OpenWithPage.Setting.Options"])

        // Check that the list is shown with all elements disabled
        mozWaitForElementToExist(app.tables.staticTexts["OPEN MAIL LINKS WITH"])
        XCTAssertFalse(app.tables.cells.staticTexts["Mail"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["Outlook"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["ProtonMail"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["Airmail"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["myMail"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["Spark"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["YMail!"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["Gmail"].isSelected)
        XCTAssertFalse(app.tables.cells.staticTexts["Fastmail"].isSelected)

        // Check that tapping on an element does nothing
        mozWaitForElementToExist(app.tables["OpenWithPage.Setting.Options"])
        app.tables.cells.staticTexts["Airmail"].waitAndTap()
        XCTAssertFalse(app.tables.cells.staticTexts["Airmail"].isSelected)

        // Check that user can go back from that setting
        navigator.nowAt(MailAppSettings)
        navigator.goto(SettingsScreen)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307058
    // Functionality is tested by UITests/NoImageModeTests, here only the UI is updated properly
    // SmokeTest
    func testImageOnOff() {
        // Select no images or hide images, check it's hidden or not
        waitUntilPageLoad()

        // Select hide images under Browsing Settings page
        let blockImagesSwitch = app.otherElements.tables.cells.switches[
            AccessibilityIdentifiers.Settings.BlockImages.title
        ]
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        app.cells[AccessibilityIdentifiers.Settings.Browsing.title].waitAndTap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Browsing.tabs])

        mozWaitForElementToExist(blockImagesSwitch)
        app.swipeUp()
        navigator.performAction(Action.ToggleNoImageMode)
        checkShowImages(showImages: false)

        // Select show images
        navigator.goto(SettingsScreen)
        navigator.nowAt(SettingsScreen)
        mozWaitForElementToExist(blockImagesSwitch)
        navigator.performAction(Action.ToggleNoImageMode)
        checkShowImages(showImages: true)
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2951435
    // Smoketest
    func testSettingsOptionSubtitles() {
        validateSettingsUIOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2989418
    func testSettingsOptionSubtitlesLandspace() {
        XCUIDevice.shared.orientation = .landscapeLeft
        validateSettingsUIOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2989420
    func testSettingsOptionSubtitlesDarkMode() {
        switchThemeToDarkOrLight(theme: "Dark")
        validateSettingsUIOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2986986
    func testSettingsOptionSubtitlesDarkModeLandscape() {
        switchThemeToDarkOrLight(theme: "Dark")
        XCUIDevice.shared.orientation = .landscapeLeft
        validateSettingsUIOptions()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2875583
    func testSettingsCrashReportsOption() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let crashReportToggle = app.switches["settings.sendCrashReports"]
        scrollToElement(crashReportToggle)
        XCTAssertEqual(crashReportToggle.value as? String, "1", "Crash report toggle in not enabled by default")
        crashReportToggle.waitAndTap()
        XCTAssertEqual(crashReportToggle.value as? String, "0", "Crash report toggle in not disabled")
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2951438
    func testBrowsingSettingsOptionSubtitles() {
        validateBrowsingUI()
        // Repeat steps for dark mode
        navigator.nowAt(SettingsScreen)
        navigator.goto(NewTabScreen)
        switchThemeToDarkOrLight(theme: "Dark")
        validateBrowsingUI()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // Repeat steps in landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        validateBrowsingUI()
        app.buttons["Done"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2951992
    func testAutofillPasswordSettingsOptionSubtitles() {
        validateAutofillAndPasswordsUI()
        // Repeat steps for dark mode
        navigator.nowAt(SettingsScreen)
        navigator.goto(NewTabScreen)
        switchThemeToDarkOrLight(theme: "Dark")
        validateAutofillAndPasswordsUI()
        navigator.nowAt(SettingsScreen)
        app.buttons["Done"].waitAndTap()
        // Repeat steps in landscape
        XCUIDevice.shared.orientation = .landscapeLeft
        validateAutofillAndPasswordsUI()
        app.buttons["Done"].waitAndTap()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2951439
    func testAutoplayOptionUI() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        // Navigate to the Autoplay settings screen
        navigator.goto(AutoplaySettings)
        // Validate UI elements
        let table = app.tables.element(boundBy: 0)
        let settingsQuery = AccessibilityIdentifiers.Settings.self
        let autoplayNotif1 = "Autoplay settings will only apply to newly opened tabs. "
        let autoplayNotif2 = "Changes cannot be applied to existing tabs unless the application is restarted."
        let allowVideo = table.cells[settingsQuery.Autoplay.allowAudioAndVideo]
        let blockVideo = table.cells[settingsQuery.Autoplay.blockAudio]
        let blockAudioVideo = table.cells[settingsQuery.Autoplay.blockAudioAndVideo]
        waitForElementsToExist(
            [
                app.staticTexts["Autoplay"],
                allowVideo,
                blockVideo,
                blockAudioVideo
            ]
        )
        XCTAssertTrue(table.staticTexts.elementContainingText(autoplayNotif1).exists)
        XCTAssertTrue(table.staticTexts.elementContainingText(autoplayNotif2).exists)
        XCTAssertTrue(allowVideo.isSelected)
        blockVideo.waitAndTap()
        XCTAssertTrue(blockVideo.isSelected)
        blockAudioVideo.waitAndTap()
        XCTAssertTrue(blockAudioVideo.isSelected)
        allowVideo.waitAndTap()
        XCTAssertTrue(allowVideo.isSelected)
        navigator.goto(BrowsingSettings)
        mozWaitForElementToExist(app.staticTexts["Browsing"])
    }

    private func validateAutofillAndPasswordsUI() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let table = app.tables.element(boundBy: 0)
        mozWaitForElementToExist(table)
        // "Autofills and passwords" sub-menu is displayed in the "Privacy" section
        let settingsQuery = AccessibilityIdentifiers.Settings.self
        let privacySection = table.staticTexts["PRIVACY"]
        let autoFillPasswords = table.cells[AccessibilityIdentifiers.Settings.AutofillsPasswords.title]
        app.swipeUp()
        XCTAssertTrue(privacySection.isAbove(element: autoFillPasswords))

        // Navigate to the Autofills and passwords settings screen
        navigator.goto(AutofillPasswordSettings)

        let settingsElements = [
            table.cells[settingsQuery.Logins.title],
            table.cells[settingsQuery.CreditCards.title],
            table.cells[settingsQuery.Address.title]
        ]

        for i in settingsElements {
            scrollToElement(i)
            mozWaitForElementToExist(i)
            XCTAssertTrue(i.isVisible(), "\(i) is not visible")
        }
        navigator.goto(SettingsScreen)
    }

    private func validateBrowsingUI() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let table = app.tables.element(boundBy: 0)
        mozWaitForElementToExist(table)
        let generalSection = table.staticTexts["GENERAL"]
        let browsingSettings = table.cells[AccessibilityIdentifiers.Settings.Browsing.title]
        XCTAssertTrue(browsingSettings.isBelow(element: generalSection))

        // Navigate to the Browsing settings screen
        navigator.goto(BrowsingSettings)
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Browsing.tabs])

        let settingsQuery = AccessibilityIdentifiers.Settings.self
        waitForElementsToExist(
            [
                app.switches[settingsQuery.Browsing.inactiveTabsSwitch],
                table.cells[settingsQuery.OpenWithMail.title],
                app.switches[settingsQuery.OfferToOpen.title],
                app.switches[settingsQuery.ShowLink.title],
                table.cells[settingsQuery.Browsing.autoPlay],
                table.cells[settingsQuery.BlockPopUp.title],
                table.cells[settingsQuery.NoImageMode.title],
                app.switches[settingsQuery.BlockExternal.title]
            ]
        )
        XCTAssertEqual(app.switches[settingsQuery.Browsing.inactiveTabsSwitch].value as? String,
                       "1",
                       "Inactive tabs - toggle in not enabled by default")
        XCTAssertEqual(app.switches[settingsQuery.OfferToOpen.title].value as? String,
                       "0",
                       "Offer to Open Copied Links - toggle is not disabled by default")
        XCTAssertEqual(app.switches[settingsQuery.ShowLink.title].value as? String,
                       "1",
                       "Show Links Previews - toggle is not enabled by default")
        app.swipeUp()
        XCTAssertEqual(app.switches[settingsQuery.Browsing.blockPopUps].value as? String,
                       "1",
                       "Block Pop-up  Windows - toggle is not enabled by default")
        XCTAssertEqual(app.switches[settingsQuery.Browsing.blockImages].value as? String,
                       "0",
                       "Block images - toggle is not disabled by default")
        XCTAssertEqual(app.switches[settingsQuery.BlockExternal.title].value as? String,
                       "0",
                       "Block Opening External Apps - toggle is not disabled by default")
        navigator.goto(SettingsScreen)
    }

    private func validateSettingsUIOptions() {
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        let table = app.tables.element(boundBy: 0)
        let settingsQuery = AccessibilityIdentifiers.Settings.self
        let settingsTitle = app.staticTexts["Settings"]
        let doneButton = app.buttons["Done"]
        let defaultBrowser = table.cells[settingsQuery.DefaultBrowser.defaultBrowser]
        mozWaitForElementToExist(table)
        XCTAssertTrue(settingsTitle.isLeftOf(rightElement: doneButton))
        XCTAssertTrue(doneButton.isAbove(element: defaultBrowser))
        XCTAssertTrue(settingsTitle.isAbove(element: defaultBrowser))
        let toolbarElement = table.cells[settingsQuery.SearchBar.searchBarSetting]
        let settingsElements = [
            defaultBrowser,
            table.cells[settingsQuery.ConnectSetting.title],
            table.cells[settingsQuery.Search.title],
            table.cells[settingsQuery.NewTab.title],
            table.cells[settingsQuery.Homepage.homeSettings],
            table.cells[settingsQuery.Browsing.title],
            table.cells[settingsQuery.Theme.title],
            table.cells[settingsQuery.AppIconSelection.settingsRowTitle],
            table.cells[settingsQuery.Siri.title],
            table.cells[settingsQuery.AutofillsPasswords.title],
            table.cells[settingsQuery.ClearData.title],
            app.switches[settingsQuery.ClosePrivateTabs.title],
            table.cells[settingsQuery.ContentBlocker.title],
            table.cells[settingsQuery.Notifications.title],
            table.cells[settingsQuery.PrivacyPolicy.title],
            table.cells[settingsQuery.SendFeedback.title],
            table.cells[settingsQuery.ShowIntroduction.title],
            table.cells[settingsQuery.SendData.sendTechnicalDataTitle],
            table.cells[settingsQuery.SendData.sendDailyUsagePingTitle],
            table.cells[settingsQuery.SendData.sendCrashReportsTitle],
            table.cells[settingsQuery.SendData.studiesTitle],
            table.cells[settingsQuery.Version.title],
            table.cells[settingsQuery.Help.title],
            table.cells[settingsQuery.RateOnAppStore.title],
            table.cells[settingsQuery.Licenses.title],
            table.cells[settingsQuery.YourRights.title]
        ]
        if !iPad() {
            mozWaitForElementToExist(toolbarElement)
            XCTAssertTrue(toolbarElement.isVisible())
        }

        for i in settingsElements {
            scrollToElement(i)
            mozWaitForElementToExist(i)
            XCTAssertTrue(i.isVisible())
        }
        app.buttons["Done"].waitAndTap()
    }
}
