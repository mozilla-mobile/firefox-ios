// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Page object for the standalone Settings → Page Summaries screen. Its "Summarize Pages" toggle
/// carries the summarize content pref key as its accessibility identifier.
@MainActor
final class SummarizeSettingsScreen {
    private let app: XCUIApplication
    private let sel: SummarizeSettingsSelectorsSet

    private var summarizeToggle: XCUIElement { sel.SUMMARIZE_SWITCH.element(in: app) }
    private var shakeGestureToggle: XCUIElement { sel.SHAKE_GESTURE_SWITCH.element(in: app) }
    private var languageCell: XCUIElement { sel.LANGUAGE_CELL.element(in: app) }

    init(app: XCUIApplication, selectors: SummarizeSettingsSelectorsSet = SummarizeSettingsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertSummarizeAndShakeTogglesAreOnByDefault() {
        BaseTestCase().waitForElementsToExist([
            summarizeToggle,
            sel.GESTURES_SECTION_HEADER.element(in: app),
            shakeGestureToggle
        ])
        XCTAssertEqual(summarizeToggle.value as? String, "1", "Summarize content - toggle is enabled by default")
        XCTAssertEqual(shakeGestureToggle.value as? String, "1", "Shake gesture - toggle is enabled by default")
    }

    func assertLanguageSectionShowsWebsiteLanguage() {
        BaseTestCase().waitForElementsToExist([
            sel.LANGUAGE_SECTION_HEADER.element(in: app),
            languageCell,
            sel.WEBSITE_LANGUAGE_VALUE.element(in: app)
        ])
    }

    /// iOS 17.4+ opens a menu and older versions an action sheet; both list the options as buttons.
    func openLanguagePicker() {
        languageCell.waitAndTap()
    }

    func assertLanguageOptionsExist() {
        BaseTestCase().waitForElementsToExist(sel.LANGUAGE_OPTIONS.map { $0.element(in: app) })
    }

    func assertSummarizeToggleIsOff() {
        BaseTestCase().mozWaitForElementToExist(summarizeToggle)
        let value = summarizeToggle.value as? String
        XCTAssertEqual(value, "0", "Expected 'Summarize Pages' switch to be OFF (0), but got \(String(describing: value))")
    }

    func assertSummarizeToggleIsOn() {
        BaseTestCase().mozWaitForElementToExist(summarizeToggle)
        let value = summarizeToggle.value as? String
        XCTAssertEqual(value, "1", "Expected 'Summarize Pages' switch to be ON (1), but got \(String(describing: value))")
    }

    func setSummarizeSwitch(on: Bool) {
        BaseTestCase().mozWaitForElementToExist(summarizeToggle)
        if (summarizeToggle.value as? String) != (on ? "1" : "0") {
            summarizeToggle.waitAndTap()
        }
    }
}
