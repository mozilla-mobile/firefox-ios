// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class SettingScreen {
    private let app: XCUIApplication
    private let sel: SettingsSelectorsSet

    init(app: XCUIApplication, selectors: SettingsSelectorsSet = SettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var clearDataCell: XCUIElement { sel.CLEAR_PRIVATE_DATA_CELL.element(in: app) }
    private var okButton: XCUIElement { sel.ALERT_OK_BUTTON.element(in: app)}
    private var toggle: XCUIElement { sel.BLOCK_POPUPS_SWITCH.element(in: app) }
    private var translationCell: XCUIElement { sel.TRANSLATION_CELL_TITLE.element(in: app) }

    func closeSettingsWithDoneButton() {
        let doneButton = sel.DONE_BUTTON.element(in: app)
        doneButton.waitAndTap()
    }

    func rotateDevice(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
    }

    func switchTheme(to theme: String) {
        BaseTestCase().switchThemeToDarkOrLight(theme: theme)
    }

    func validatePrivacyOptions(timeout: TimeInterval = TIMEOUT_LONG) {
        let settingsTable = sel.SETTINGS_TABLE.element(in: app)

        let requiredElements = [
            settingsTable.cells[sel.AUTOFILLS_PASSWORDS_CELL.value],
            settingsTable.cells[sel.CLEAR_DATA_CELL.value],
            settingsTable.switches[sel.CLOSE_PRIVATE_TABS_SWITCH.value],
            settingsTable.cells[sel.CONTENT_BLOCKER_CELL.value],
            settingsTable.cells[sel.NOTIFICATIONS_CELL.value],
            settingsTable.cells[sel.PRIVACY_POLICY_CELL.value]
        ]
        BaseTestCase().waitForElementsToExist(requiredElements, timeout: timeout)
    }

    func validateAutofillPasswordOptions() {
        let settingsTable = sel.SETTINGS_TABLE.element(in: app)

        let requiredElements = [
            settingsTable.cells[sel.LOGINS_CELL.value],
            settingsTable.cells[sel.CREDIT_CARDS_CELL.value],
            settingsTable.cells[sel.ADDRESS_CELL.value]
        ]
        BaseTestCase().waitForElementsToExist(requiredElements)
    }

    func clearPrivateDataAndConfirm() {
        clearDataCell.waitAndTap()

        BaseTestCase().mozWaitForElementToExist(okButton)
        okButton.waitAndTap()
    }

    func tryTapClearPrivateDataButton() {
        clearDataCell.waitAndTap()
    }

    func assertConfirmationAlertNotPresent() {
        BaseTestCase().mozWaitForElementToNotExist(okButton)
    }

    func waitForClearPrivateDataCellSync() {
        BaseTestCase().mozWaitForElementToExist(clearDataCell)
    }

    func swipeUpFromNewTabCell() {
        let newTab = sel.NEW_TAB_CELL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(newTab)
        newTab.swipeUp()
    }

    func waitForBrowsingLinksSection() {
        let browsingSection = sel.BROWSING_LINKS_SECTION.element(in: app)
        BaseTestCase().mozWaitForElementToExist(browsingSection)
    }

    func assertBlockPopUpsSwitchIsOn() {
        BaseTestCase().mozWaitForElementToExist(toggle)

        let value = toggle.value as? String
        XCTAssertEqual(value, "1", "Expected 'Block Pop-Ups' switch to be ON (value = 1), but got \(String(describing: value))")
    }

    func tapOnBlockPopupsSwitch() {
        toggle.waitAndTap()
    }

    func assertBlockPopUpsSwitchIsOff() {
        let toggle = sel.BLOCK_POPUPS_SWITCH.element(in: app)
        BaseTestCase().mozWaitForElementToExist(toggle)

        let value = toggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Block Pop-Ups' switch to be OFF (value = 0), but got \(String(describing: value))")
    }

    func navigateBackToHomePage() {
        sel.TITLE.element(in: app).waitAndTap()
        sel.NAVIGATIONBAR.element(in: app).waitAndTap()
    }

    func connectSettingSwipeUp() {
        let connectSetting = sel.CONNECT_SETTING.element(in: app)
        BaseTestCase().mozWaitForElementToExist(connectSetting)
        connectSetting.swipeUp()
    }

    func assertSettingsScreenExists() {
        let table = app.tables.element(boundBy: 0)
        BaseTestCase().mozWaitForElementToExist(table)
    }

    func assertLayout() {
        let title = sel.SETTINGS_TITLE.element(in: app)
        let done = sel.DONE_BUTTON.element(in: app)
        let defaultBrowser = sel.DEFAULT_BROWSER_CELL.element(in: app)

        BaseTestCase().mozWaitForElementToExist(title)
        XCTAssertTrue(title.isLeftOf(rightElement: done))
        XCTAssertTrue(done.isAbove(element: defaultBrowser))
        XCTAssertTrue(title.isAbove(element: defaultBrowser))
    }

    func assertAllRowsVisible() {
        let table = app.tables.element(boundBy: 0)
        BaseTestCase().mozWaitForElementToExist(table)

        // Toolbar check only on iPhone
        if !BaseTestCase().iPad() {
            let toolbar = sel.TOOLBAR_CELL.element(in: app)
            BaseTestCase().mozWaitForElementToExist(toolbar)
            XCTAssertTrue(toolbar.isVisible())
        }

        // Iterate over all expected cells
        for selector in sel.ALL_CELLS() {
            let element = selector.element(in: app)
            BaseTestCase().scrollToElement(element)
            BaseTestCase().mozWaitForElementToExist(element)
            XCTAssertTrue(element.isVisible(), "\(selector.description) is not visible")
        }
    }

    func openBrowsingSettings() {
        let cell = sel.BROWSING_CELL_TITLE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(cell)
        cell.waitAndTap()
    }

    func waitForBlockImagesSwitch() -> XCUIElement {
        let sw = app.otherElements.tables.cells.switches[sel.BLOCK_IMAGES_SWITCH_TITLE.value]
        BaseTestCase().mozWaitForElementToExist(sw)
        return sw
    }

    func assertShowImagesState(showImages: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
        let noImageStatusSwitch = app.otherElements.tables.cells.switches[sel.NO_IMAGE_MODE_STATUS_SWITCH.value]
        BaseTestCase().mozWaitForElementToExist(noImageStatusSwitch)

        let expectedValue = showImages ? "0" : "1"
        let actualValue = noImageStatusSwitch.value as? String

        XCTAssertEqual(
            actualValue,
            expectedValue,
            "Image display state is incorrect. Expected \(expectedValue) but got \(actualValue ?? "nil")",
            file: file,
            line: line
        )
    }

    func openTranslationSettings() {
        BaseTestCase().mozWaitForElementToExist(translationCell)
        translationCell.waitAndTap()
    }

    func assertTranslationSettingsDoesNotExist() {
        BaseTestCase().mozWaitForElementToNotExist(translationCell)
    }
}
