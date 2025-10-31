// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class SettingScreen {
    private let app: XCUIApplication
    private let sel: SettingsSelectorsSet

    init(app: XCUIApplication, selectors: SettingsSelectorsSet = SettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var clearDataCell: XCUIElement { sel.CLEAR_PRIVATE_DATA_CELL.element(in: app) }
    private var okButton: XCUIElement { sel.ALERT_OK_BUTTON.element(in: app)}

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
}
