// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

// ⚠️ Drives the iOS document picker presented by "Save to Files": a system remote view hosted by the
// app, with English-only labels, that opens on whichever location it was last left in.
@MainActor
final class DocumentPickerScreen {
    private let app: XCUIApplication
    private let sel: DocumentPickerSelectorsSet

    init(app: XCUIApplication, selectors: DocumentPickerSelectorsSet = DocumentPickerSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var saveButton: XCUIElement { sel.SAVE_BUTTON.element(in: app) }
    private var untaggedFileNameField: XCUIElement { sel.UNTAGGED_FILE_NAME_FIELD.element(in: app) }

    /// Anchors on the picker's own Save button rather than a location label such as "On My iPhone":
    /// the picker opens on whichever location was last used, so the label is not reliably present.
    func assertOpened(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToExist(saveButton, timeout: timeout)
    }

    func assertFileNameIsPrefilled(_ name: String, timeout: TimeInterval = TIMEOUT) {
        let field = fileNameField(timeout: timeout)
        XCTAssertEqual(field?.value as? String, name, "The picker should offer the document currently displayed")
    }

    /// iOS 26 tags the file name field; older iOS leaves it untagged, so fall back to the text field
    /// hosting the picker's Tags button.
    private func fileNameField(timeout: TimeInterval) -> XCUIElement? {
        let taggedField = sel.FILE_NAME_FIELD.element(in: app)
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if taggedField.exists { return taggedField }
            if untaggedFileNameField.exists { return untaggedFileNameField }
            usleep(100_000)
        } while Date() < deadline
        XCTFail("Timed out waiting for the document picker's file name field in \(timeout) seconds")
        return nil
    }

    /// A freshly booted simulator can show Save before the picker accepts it, so wait for it to be
    /// enabled and tap once more if the first tap left the picker open.
    func save() {
        tapSaveWhenEnabled()
        resolveDuplicateNameAlertIfPresented()
        guard isStillOpenAfterSave() else { return }
        tapSaveWhenEnabled()
        resolveDuplicateNameAlertIfPresented()
    }

    private func tapSaveWhenEnabled(timeout: TimeInterval = TIMEOUT_LONG) {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            if let button = onScreenSaveButton, button.isEnabled, button.isHittable {
                button.tap()
                return
            }
            usleep(250_000)
        } while Date() < deadline
        XCTFail("The document picker's Save button never became enabled in \(timeout) seconds. \(pickerState)")
    }

    /// Jenkins can match a "Save" button with no valid frame, which is never hittable, so only
    /// consider matches laid out on screen.
    private var onScreenSaveButton: XCUIElement? {
        sel.SAVE_BUTTON.query(in: app).allElementsBoundByIndex.first {
            !$0.frame.isEmpty && app.frame.intersects($0.frame)
        }
    }

    /// Jenkins drops report attachments, so the failure message must describe the picker. Avoids
    /// isHittable, which itself fails when a Save match has no valid frame.
    private var pickerState: String {
        let saveMatches = sel.SAVE_BUTTON.query(in: app).allElementsBoundByIndex
            .map { "frame: \($0.frame), enabled: \($0.isEnabled)" }
        let titles = app.navigationBars.allElementsBoundByIndex.map(\.identifier)
        let alerts = app.alerts.allElementsBoundByIndex.map(\.label)
        return "Save matches: \(saveMatches), navigation bars: \(titles), alerts: \(alerts)"
    }

    /// The Save button turns into a spinner once the save is accepted, so an enabled Save button
    /// still on screen after the probe means the tap was ignored.
    private func isStillOpenAfterSave() -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: saveButton)
        guard XCTWaiter().wait(for: [expectation], timeout: TIMEOUT_PICKER_PROBE) != .completed else { return false }
        return onScreenSaveButton?.isEnabled ?? false
    }

    /// Saving a document whose name is already taken prompts before overwriting; keep both copies.
    /// A tap during the alert's appear animation is ignored, so tap again while the alert stays up.
    private func resolveDuplicateNameAlertIfPresented() {
        let alert = app.alerts.firstMatch
        guard alert.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) else { return }
        guard let button = ["Keep Both", "Replace"].map({ alert.buttons[$0] }).first(where: \.exists) else { return }
        for _ in 1...2 {
            button.mozWaitElementHittable(timeout: TIMEOUT)
            button.tap()
            if BaseTestCase().mozWaitForElementToNotExist(alert, timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) {
                return
            }
        }
        XCTFail("The duplicate name alert stayed open. \(pickerState)")
    }

    /// The Save button turns into a spinner while the file is written, so it vanishes before the picker
    /// does; the file name field stays up until the picker is really gone, unless an alert hides it.
    func assertDismissed(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToNotExist(app.alerts.firstMatch, timeout: TIMEOUT_PICKER_PROBE)
        BaseTestCase().mozWaitForElementToNotExist(saveButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToNotExist(sel.FILE_NAME_FIELD.element(in: app), timeout: timeout)
        BaseTestCase().mozWaitForElementToNotExist(untaggedFileNameField, timeout: timeout)
    }
}
