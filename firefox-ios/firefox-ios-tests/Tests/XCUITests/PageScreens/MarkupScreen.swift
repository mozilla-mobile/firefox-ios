// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class MarkupScreen {
    private let app: XCUIApplication
    private let sel: MarkupSelectorsSet

    // Entering markup can be ignored while QuickLook is still loading the document, so the control is
    // tapped again as long as the palette has not shown up.
    private let markupEntryAttempts = 3

    init(app: XCUIApplication, selectors: MarkupSelectorsSet = MarkupSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var palette: XCUIElement { sel.PALETTE.element(in: app) }
    private var penTool: XCUIElement { sel.PEN_TOOL.element(in: app) }
    private var quickLookMarkupToggle: XCUIElement { sel.QUICK_LOOK_MARKUP_TOGGLE.element(in: app) }
    private var markupButton: XCUIElement { sel.MARKUP_BUTTON.element(in: app) }
    private var markupSwitch: XCUIElement { sel.MARKUP_SWITCH.element(in: app) }
    private var closeButton: XCUIElement { sel.CLOSE_BUTTON.element(in: app) }

    func assertMarkupToolIsOpen() {
        let base = BaseTestCase()
        guard #available(iOS 26, *) else {
            assertMarkupControlIsShown()
            return
        }
        if base.iPad() {
            // On iPad the palette renders inline and the Markup control is a switch, not a button.
            base.mozWaitForElementToExist(markupSwitch, timeout: TIMEOUT_LONG)
            base.mozWaitForElementToExist(closeButton, timeout: TIMEOUT_LONG)
        } else {
            assertPaletteIsOpen()
        }
    }

    // Share "Markup" either opens PencilKit straight away or opens QuickLook in preview mode behind a
    // markup control, and which one happens varies by share entry point, so both are handled.
    private func assertPaletteIsOpen() {
        for _ in 0..<markupEntryAttempts {
            if palette.mozWaitForElementToExist(timeout: TIMEOUT, failOnTimeout: false) {
                BaseTestCase().mozWaitForElementToExist(penTool, timeout: TIMEOUT_LONG)
                return
            }
            guard tapMarkupEntryControl() else { break }
        }
        XCTFail("The Markup palette did not open. \(observedMarkupState())")
    }

    /// Taps whichever markup control QuickLook exposes, and reports `false` when neither is on screen
    /// so the caller stops retrying.
    private func tapMarkupEntryControl() -> Bool {
        for control in [quickLookMarkupToggle, markupButton, markupSwitch] where control.exists {
            control.waitAndTap()
            return true
        }
        return false
    }

    private func observedMarkupState() -> String {
        let onScreen = [
            ("QuickLook markup toggle", quickLookMarkupToggle),
            ("Markup button", markupButton),
            ("Markup switch", markupSwitch),
            ("Pen tool", penTool)
        ].filter { $0.1.exists }.map { $0.0 }
        return onScreen.isEmpty ? "No markup control was on screen" : "On screen: \(onScreen.joined(separator: ", "))"
    }

    // Before iOS 26 the tool exposes the Markup control itself rather than a PencilKit palette.
    private func assertMarkupControlIsShown() {
        guard !markupSwitch.mozWaitForElementToExist(timeout: TIMEOUT_LONG, failOnTimeout: false) else { return }
        BaseTestCase().mozWaitForElementToExist(markupButton, timeout: TIMEOUT_LONG)
    }
}
