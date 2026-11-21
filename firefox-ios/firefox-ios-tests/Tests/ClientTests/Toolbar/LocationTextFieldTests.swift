// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

@MainActor
final class LocationTextFieldTests: XCTestCase {
    private var textField: LocationTextField!
    private var themeManager: MockThemeManager!
    private var window: UIWindow!
    private var delegate: MockLocationTextFieldDelegate!

    override func setUp() async throws {
        try await super.setUp()
        textField = LocationTextField(frame: .zero)
        themeManager = MockThemeManager()
        delegate = MockLocationTextFieldDelegate()
        textField.autocompleteDelegate = delegate
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 44))
        window.addSubview(textField)
        window.makeKeyAndVisible()
    }

    override func tearDown() async throws {
        textField.resignFirstResponder()
        textField = nil
        themeManager = nil
        delegate = nil
        window = nil
        try await super.tearDown()
    }

    private func makeTextFieldEditing() {
        textField.becomeFirstResponder()
    }

    // The suggestion must not be marked text: IME keyboards treat marked text as an active
    // composition, so Return confirms the "composition" instead of submitting (FXIOS-16999).
    func testSetAutocompleteSuggestion_rendersSuggestionAsLabelNotMarkedText() {
        makeTextFieldEditing()
        simulateTyping("google")

        textField.setAutocompleteSuggestion("google.com")

        XCTAssertNil(textField.markedTextRange, "The suggestion must not be set as marked text.")
        XCTAssertEqual(textField.text, "google")
        XCTAssertTrue(textField.isSelectionActive)
        XCTAssertEqual(textField.accessibilityValue, "google.com")
    }

    func testTextFieldShouldReturn_commitsSuggestion() {
        makeTextFieldEditing()
        simulateTyping("google")
        textField.setAutocompleteSuggestion("google.com")

        let result = textField.textFieldShouldReturn(textField)

        XCTAssertTrue(result)
        XCTAssertTrue(delegate.shouldReturnCalled)
        XCTAssertEqual(delegate.shouldReturnText, "google.com")
        XCTAssertEqual(textField.text, "google.com")
        XCTAssertFalse(textField.isSelectionActive)
    }

    func testSetAutocompleteSuggestion_duringIMEComposition_doesNotShowSuggestion() {
        makeTextFieldEditing()
        textField.text = "google"
        // Simulate an active IME composition (e.g. Japanese kana input).
        textField.setMarkedText("にほん", selectedRange: NSRange())
        XCTAssertNotNil(textField.markedTextRange)

        textField.setAutocompleteSuggestion("google.com")

        XCTAssertFalse(textField.isSelectionActive)
        XCTAssertNotNil(textField.markedTextRange, "The ongoing composition must not be disturbed.")
    }

    func testDeleteBackward_withSuggestion_removesOnlySuggestion() {
        makeTextFieldEditing()
        simulateTyping("google")
        textField.setAutocompleteSuggestion("google.com")

        textField.deleteBackward()

        XCTAssertEqual(textField.text, "google")
        XCTAssertFalse(textField.isSelectionActive)
    }

    func testDeleteBackward_duringIMEComposition_deletesCompositionCharacter() {
        makeTextFieldEditing()
        textField.text = "google"
        textField.setMarkedText("g", selectedRange: NSRange())
        XCTAssertNotNil(textField.markedTextRange)

        textField.deleteBackward()

        XCTAssertEqual(textField.text, "google", "Delete should shrink the composition, not the typed text.")
        XCTAssertNil(textField.markedTextRange)
    }

    func testTyping_removesSuggestion() {
        makeTextFieldEditing()
        simulateTyping("google")
        textField.setAutocompleteSuggestion("google.com")
        XCTAssertTrue(textField.isSelectionActive)

        simulateTyping("1")

        XCTAssertFalse(textField.isSelectionActive)
        XCTAssertEqual(textField.text, "google1")
    }

    func testApplyTheme_keepsSuggestionVisible() {
        makeTextFieldEditing()
        simulateTyping("google")
        textField.setAutocompleteSuggestion("google.com")
        XCTAssertTrue(textField.isSelectionActive)

        themeManager.setManualTheme(to: .dark)
        textField.applyTheme(theme: themeManager.getCurrentTheme(for: .XCTestDefaultUUID))

        XCTAssertTrue(textField.isSelectionActive)
        XCTAssertEqual(textField.accessibilityValue, "google.com")
    }

    // MARK: - Helpers

    private func simulateTyping(_ string: String) {
        for character in string {
            let location = (textField.text ?? "").count
            _ = textField.textField(
                textField,
                shouldChangeCharactersIn: NSRange(location: location, length: 0),
                replacementString: String(character)
            )
            textField.text = (textField.text ?? "") + String(character)
        }
    }
}

@MainActor
private final class MockLocationTextFieldDelegate: LocationTextFieldDelegate {
    var shouldReturnCalled = false
    var shouldReturnText: String?

    func locationTextFieldDidEnterText(_ text: String) {}

    func locationTextFieldShouldReturn(_ textField: LocationTextField) -> Bool {
        shouldReturnCalled = true
        shouldReturnText = textField.text
        return true
    }

    func locationTextFieldShouldClear() -> Bool { return true }
    func locationTextFieldDidBeginEditing(_ textField: UITextField) {}
    func locationTextFieldDidEndEditing() {}
    func locationTextFieldNeedsSearchReset() {}
    func locationTextFieldDidDisplayEditingAccessoryButton(_ button: UIButton, contextualHintType: String) {}
    func locationTextFieldDidHideEditingAccessoryButton() {}
}
