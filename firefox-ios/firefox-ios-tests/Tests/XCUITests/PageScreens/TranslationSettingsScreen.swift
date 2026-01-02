// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class TranslationSettingsScreen {
    private let app: XCUIApplication
    private let sel: TranslationSettingsSelectorsSet

    private var translationToggle: XCUIElement { sel.TRANSLATION_SWITCH.element(in: app) }

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

    func assertTranslationSwitchIsOff() {
        BaseTestCase().mozWaitForElementToExist(translationToggle)

        let value = translationToggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Enable Translations' switch to be OFF (value = 0), but got \(String(describing: value))")
    }
}
