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
        let predicate = NSPredicate(format: "exists == true && hittable == true && enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: saveButton)
        guard XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed else {
            XCTFail("The document picker's Save button never became enabled in \(timeout) seconds")
            return
        }
        saveButton.tap()
    }

    /// The Save button turns into a spinner once the save is accepted, so an enabled Save button
    /// still on screen after the probe means the tap was ignored.
    private func isStillOpenAfterSave() -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: saveButton)
        guard XCTWaiter().wait(for: [expectation], timeout: TIMEOUT_PICKER_PROBE) != .completed else { return false }
        return saveButton.exists && saveButton.isEnabled
    }

    /// Saving a document whose name is already taken in the chosen folder prompts before overwriting.
    /// Keep both copies, so an earlier save is never destroyed and the new file is suffixed instead.
    private func resolveDuplicateNameAlertIfPresented() {
        let alert = app.alerts.firstMatch
        guard alert.mozWaitForElementToExist(timeout: TIMEOUT_PICKER_PROBE, failOnTimeout: false) else { return }
        for label in ["Keep Both", "Replace"] where alert.buttons[label].exists {
            alert.buttons[label].waitAndTap()
            return
        }
    }

    /// The Save button turns into a spinner while the file is written, so it vanishes before the picker
    /// does; the file name field stays up until the picker is really gone.
    func assertDismissed(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToNotExist(saveButton, timeout: timeout)
        BaseTestCase().mozWaitForElementToNotExist(sel.FILE_NAME_FIELD.element(in: app), timeout: timeout)
        BaseTestCase().mozWaitForElementToNotExist(untaggedFileNameField, timeout: timeout)
    }
}
