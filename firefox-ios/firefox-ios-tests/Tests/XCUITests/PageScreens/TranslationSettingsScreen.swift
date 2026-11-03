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
    private var languagePickerCancelButton: XCUIElement { sel.LANGUAGE_PICKER_CANCEL_BUTTON.element(in: app) }

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
            languagePickerCancelButton,
            languagePickerSearchField
        ])
    }

    func assertLanguagePickerListIsNotEmpty() {
        BaseTestCase().mozWaitForElementToExist(languagePickerList.cells.firstMatch)
        XCTAssertGreaterThan(languagePickerList.cells.count, 1, "Expected the 'Select Language' list to show languages")
    }

    func tapLanguagePickerSearchField() {
        languagePickerSearchField.waitAndTap()
    }

    /// Active search focuses the field and shows the keyboard and a cancel/X button; the header hides only on iPhone,
    /// since the iPad form sheet keeps its navigation bar.
    func assertLanguagePickerSearchIsActive() {
        BaseTestCase().waitForElementsToExist([app.keyboards.firstMatch, languagePickerCancelButton])
        XCTAssertTrue(languagePickerSearchField.waitForKeyboardFocus(), "The search field should have keyboard focus")
        let header = languagePickerNavBar.staticTexts[sel.LANGUAGE_PICKER_NAVBAR.value]
        if BaseTestCase().iPad() {
            BaseTestCase().mozWaitForElementToExist(header)
        } else {
            BaseTestCase().mozWaitForElementToNotExist(header)
        }
    }

    func tapLanguagePickerCancelButton() {
        languagePickerCancelButton.waitAndTap()
    }

    func assertLanguagePickerSearchIsInactive() {
        BaseTestCase().mozWaitForElementToNotExist(app.keyboards.firstMatch)
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
        let matchingText = NSPredicate(
            format: "elementType == %d AND label CONTAINS[c] %@",
            XCUIElement.ElementType.staticText.rawValue,
            language
        )
        let matchingCells = languagePickerList.cells.containing(matchingText)
        let deadline = Date().addingTimeInterval(timeout)
        var isFiltered = false
        repeat {
            let cellCount = languagePickerList.cells.count
            isFiltered = cellCount > 0 && matchingCells.count == cellCount
            if !isFiltered { usleep(200_000) }
        } while !isFiltered && Date() < deadline
        XCTAssertTrue(isFiltered, "Expected only '\(language)' results in the 'Select Language' list")
    }

    func selectLanguageInPicker(_ language: String) {
        languagePickerList.staticTexts[language].waitAndTap()
    }

    func assertLanguagePickerIsDismissed() {
        BaseTestCase().mozWaitForElementToNotExist(languagePickerList)
    }

    func assertPreferredLanguageExists(_ language: String) {
        BaseTestCase().mozWaitForElementToExist(app.collectionViews.cells.staticTexts[language])
    }

    func assertPreferredLanguageDoesNotExist(_ language: String) {
        BaseTestCase().mozWaitForElementToNotExist(app.collectionViews.cells.staticTexts[language])
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
        BaseTestCase().mozWaitForElementToExist(removeIcon(in: preferredLanguageCell(containingText: language)))
    }

    func assertDeviceLanguageIsNotRemovable() {
        BaseTestCase().mozWaitForElementToExist(deviceLanguageCell)
        XCTAssertFalse(removeIcon(in: deviceLanguageCell).exists, "The device language should have no remove (-) control")
    }

    func assertReorderHandleExists(for language: String) {
        let handle = preferredLanguageCell(containingText: language).buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", sel.REORDER_HANDLE.value)
        ).firstMatch
        BaseTestCase().mozWaitForElementToExist(handle)
    }

    func removeLanguage(_ language: String) {
        removeIcon(in: preferredLanguageCell(containingText: language)).waitAndTap()
    }

    private var deviceLanguageCell: XCUIElement {
        preferredLanguageCell(containingText: String.Settings.Translation.PreferredLanguages.DeviceLanguage)
    }

    private func preferredLanguageCell(containingText text: String) -> XCUIElement {
        let label = NSPredicate(
            format: "elementType == %d AND label == %@",
            XCUIElement.ElementType.staticText.rawValue,
            text
        )
        return app.collectionViews.cells.containing(label).firstMatch
    }

    /// The edit-mode delete (-) accessory is exposed as an image, not a button.
    private func removeIcon(in cell: XCUIElement) -> XCUIElement {
        cell.images[sel.REMOVE_LANGUAGE_ICON.value]
    }
}
