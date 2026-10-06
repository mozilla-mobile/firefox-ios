// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Page object for the Settings → AI Controls screen. Its SwiftUI toggles have no accessibility
/// identifiers, so each is matched by a fragment of its visible label.
@MainActor
final class AIControlsScreen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    /// The "Block AI Enhancements" kill switch. Turning it on force-disables all AI sub-features.
    private var blockAIEnhancementsToggle: XCUIElement { toggle(labelContaining: "Block AI Enhancements") }
    private var translationToggle: XCUIElement { toggle(labelContaining: "Translation") }
    private var pageSummariesToggle: XCUIElement { toggle(labelContaining: "Page Summaries") }

    private func toggle(labelContaining fragment: String) -> XCUIElement {
        app.switches.matching(NSPredicate(format: "label CONTAINS[c] %@", fragment)).firstMatch
    }

    func assertScreenShown() {
        let navBar = app.navigationBars["AI Controls"]
        BaseTestCase().mozWaitForElementToExist(navBar)
        BaseTestCase().mozWaitForElementToExist(blockAIEnhancementsToggle)
    }

    // MARK: - Block AI Enhancements kill switch

    func turnOnBlockAIEnhancements() {
        setToggle(blockAIEnhancementsToggle, on: true)
    }

    func turnOffBlockAIEnhancements() {
        setToggle(blockAIEnhancementsToggle, on: false)
    }

    // MARK: - Individual feature toggles

    func setPageSummariesToggle(on: Bool) {
        setToggle(pageSummariesToggle, on: on)
    }

    func turnOffTranslationToggle() {
        setToggle(translationToggle, on: false)
    }

    func turnOffPageSummariesToggle() {
        setToggle(pageSummariesToggle, on: false)
    }

    func assertTranslationToggleIsOn() {
        assertToggle(translationToggle, isOn: true, name: "Translation")
    }

    func assertTranslationToggleIsOff() {
        assertToggle(translationToggle, isOn: false, name: "Translation")
    }

    func assertPageSummariesToggleIsOn() {
        assertToggle(pageSummariesToggle, isOn: true, name: "Page Summaries")
    }

    func assertPageSummariesToggleIsOff() {
        assertToggle(pageSummariesToggle, isOn: false, name: "Page Summaries")
    }

    // MARK: - Helpers

    /// The matched element spans the whole row, label included. Tapping its centre lands on the label,
    /// which iOS 16 ignores, so the nested switch control is tapped instead.
    private func setToggle(_ toggle: XCUIElement, on: Bool) {
        BaseTestCase().mozWaitForElementToExist(toggle)
        guard (toggle.value as? String) != (on ? "1" : "0") else { return }
        let control = toggle.switches.firstMatch
        (control.exists ? control : toggle).waitAndTap()
    }

    private func assertToggle(_ toggle: XCUIElement, isOn: Bool, name: String) {
        BaseTestCase().mozWaitForElementToExist(toggle)
        let value = toggle.value as? String
        let expected = isOn ? "1" : "0"
        XCTAssertEqual(value,
                       expected,
                       "Expected '\(name)' toggle to be \(isOn ? "ON" : "OFF") (\(expected)), got \(String(describing: value))")
    }
}
