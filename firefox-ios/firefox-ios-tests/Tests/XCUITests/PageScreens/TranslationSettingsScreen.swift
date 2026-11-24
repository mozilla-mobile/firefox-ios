// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class TranslationSettingsScreen {
    private let app: XCUIApplication
    private let sel: TranslationSettingsSelectorsSet

    private var translationToggle: XCUIElement { sel.TRANSLATION_SWITCH.element(in: app) }
    private var languagePickerNavBar: XCUIElement { sel.LANGUAGE_PICKER_NAVBAR.element(in: app) }
    private var languagePickerList: XCUIElement { sel.LANGUAGE_PICKER_LIST.element(in: app) }
    private var languagePickerSearchField: XCUIElement { sel.LANGUAGE_PICKER_SEARCH_FIELD.element(in: app) }
    private var languagePickerCloseButton: XCUIElement { sel.LANGUAGE_PICKER_CLOSE_BUTTON.element(in: app) }
    private var keyboard: XCUIElement { sel.KEYBOARD.element(in: app) }

    /// iPhone on iOS 26 ends search with a "close" button in the field. Elsewhere the nav bar's Cancel does it:
    /// below iOS 26 the search bar's Cancel replaces the sheet's, and iPad has no search cancel of its own.
    private var languagePickerSearchCancelButton: XCUIElement {
        if #available(iOS 26, *), !BaseTestCase().iPad() {
            return sel.LANGUAGE_PICKER_SEARCH_CLOSE_BUTTON_iOS26.element(in: app)
        }
        return languagePickerCloseButton
    }

    init(app: XCUIApplication, selectors: TranslationSettingsSelectorsSet = TranslationSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertNavBarVisible() {
        BaseTestCase().waitForElementsToExist([
            sel.NAVBAR.element(in: app)
        ])
    }

    func tapOnBackButton() {
        var backButton = sel.BACK_BUTTON.element(in: app)
        if #available(iOS 26, *) {
            backButton = sel.BACK_BUTTON_iOS26.element(in: app)
        }
        backButton.waitAndTap()
    }

    func assertTranslationSwitchIsOn() {
        BaseTestCase().mozWaitForElementToExist(translationToggle)

        let value = translationToggle.value as? String
        XCTAssertEqual(value, "1", "Expected 'Enable Translations' switch to be ON (value = 1), but got \(String(describing: value))")
    }

    func tapOnTranslationSwitch() {
        translationToggle.waitAndTap()
    }

    func setTranslationSwitch(on: Bool) {
        BaseTestCase().mozWaitForElementToExist(translationToggle)
        if (translationToggle.value as? String) != (on ? "1" : "0") {
            translationToggle.waitAndTap()
        }
    }

    func assertTranslationSwitchIsOff() {
        BaseTestCase().mozWaitForElementToExist(translationToggle)

        let value = translationToggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Enable Translations' switch to be OFF (value = 0), but got \(String(describing: value))")
    }

    func tapAddLanguage() {
        sel.ADD_LANGUAGE_CELL.element(in: app).waitAndTap()
    }

    func assertAddLanguageIs(visible: Bool) {
        let addLanguage = sel.ADD_LANGUAGE_CELL.element(in: app)
        if visible {
            BaseTestCase().mozWaitForElementToExist(addLanguage)
        } else {
            BaseTestCase().mozWaitForElementToNotExist(addLanguage)
        }
    }

    func assertLanguagePickerIsDisplayed() {
        BaseTestCase().waitForElementsToExist([
            languagePickerNavBar,
            languagePickerCloseButton,
            languagePickerSearchField
        ])
    }

    func assertLanguagePickerListIsNotEmpty() {
        let rows = sel.LANGUAGE_PICKER_ROW
        BaseTestCase().mozWaitForElementToExist(rows.element(in: app))
        XCTAssertGreaterThan(rows.query(in: app).count, 1, "Expected the 'Select Language' list to show languages")
    }

    func tapLanguagePickerSearchField() {
        languagePickerSearchField.waitAndTap()
    }

    /// Active search focuses the field and shows the keyboard and a way to end it; the header hides only on iPhone,
    /// since the iPad form sheet keeps its navigation bar.
    func assertLanguagePickerSearchIsActive() {
        BaseTestCase().waitForElementsToExist([keyboard, languagePickerSearchCancelButton])
        XCTAssertTrue(languagePickerSearchField.waitForKeyboardFocus(), "The search field should have keyboard focus")
        let header = sel.LANGUAGE_PICKER_HEADER.element(in: app)
        if BaseTestCase().iPad() {
            BaseTestCase().mozWaitForElementToExist(header)
        } else {
            BaseTestCase().mozWaitForElementToNotExist(header)
        }
    }

    func tapLanguagePickerSearchCancelButton() {
        languagePickerSearchCancelButton.waitAndTap()
    }

    func tapLanguagePickerCloseButton() {
        languagePickerCloseButton.waitAndTap()
    }

    func assertLanguagePickerSearchIsInactive() {
        BaseTestCase().mozWaitForElementToNotExist(keyboard)
        assertLanguagePickerIsDisplayed()
    }

    func searchLanguagePicker(for text: String) {
        XCTAssertTrue(
            languagePickerSearchField.tapAndTypeTextWhenFocused(text),
            "The search field never got keyboard focus, so '\(text)' was not typed"
        )
    }

    /// The matching row is already on screen before filtering, so poll until every row matches.
    func assertLanguagePickerListIsFiltered(to language: String, timeout: TimeInterval = TIMEOUT) {
        let rows = sel.LANGUAGE_PICKER_ROW.query(in: app)
        let matchingRows = sel.languagePickerRows(containing: language).query(in: app)
        let predicate = NSPredicate { _, _ in
            let rowCount = rows.count
            return rowCount > 0 && matchingRows.count == rowCount
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
            XCTFail("Expected only '\(language)' results in the 'Select Language' list")
        }
    }

    func selectLanguageInPicker(_ language: String) {
        sel.languagePickerOption(language).element(in: app).waitAndTap()
    }

    func assertLanguagePickerIsDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(languagePickerList)
    }

    func assertPreferredLanguageExists(_ language: String) {
        BaseTestCase().mozWaitForElementToExist(sel.preferredLanguage(language).element(in: app))
    }

    func assertPreferredLanguageDoesNotExist(_ language: String) {
        BaseTestCase().mozWaitForElementToNotExist(sel.preferredLanguage(language).element(in: app))
    }

    func assertDeviceLanguageExists() {
        BaseTestCase().mozWaitForElementToExist(deviceLanguageCell)
    }

    func tapEditButton() {
        sel.EDIT_BUTTON.element(in: app).waitAndTap()
    }

    func tapDoneButton() {
        sel.DONE_BUTTON.element(in: app).waitAndTap()
    }

    func assertLanguageIsRemovable(_ language: String) {
        BaseTestCase().mozWaitForElementToExist(sel.removeLanguageIcon(inCellContaining: language).element(in: app))
    }

    func assertDeviceLanguageIsNotRemovable() {
        BaseTestCase().mozWaitForElementToExist(deviceLanguageCell)
        XCTAssertFalse(sel.removeLanguageIcon(inCellContaining: deviceLanguage).element(in: app).exists,
                       "The device language should have no remove (-) control")
    }

    func assertReorderHandleExists(for language: String) {
        BaseTestCase().mozWaitForElementToExist(sel.reorderHandle(inCellContaining: language).element(in: app))
    }

    func removeLanguage(_ language: String) {
        sel.removeLanguageIcon(inCellContaining: language).element(in: app).waitAndTap()
    }

    private var deviceLanguage: String { String.Settings.Translation.PreferredLanguages.DeviceLanguage }

    private var deviceLanguageCell: XCUIElement {
        sel.preferredLanguageCell(containing: deviceLanguage).element(in: app)
    }
}
