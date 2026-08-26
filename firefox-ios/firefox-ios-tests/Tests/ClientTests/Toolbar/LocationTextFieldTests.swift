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

    override func setUp() async throws {
        try await super.setUp()
        textField = LocationTextField(frame: .zero)
        themeManager = MockThemeManager()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 44))
        window.addSubview(textField)
        window.makeKeyAndVisible()
    }

    override func tearDown() async throws {
        textField.resignFirstResponder()
        textField = nil
        themeManager = nil
        window = nil
        try await super.tearDown()
    }

    private func makeTextFieldEditing() {
        textField.becomeFirstResponder()
    }

    func testHandleInputModeDidChange_withNoLastMarkedText_doesNothing() {
        textField.text = "www.wikipedia.com"
        textField.setMarkedText("", selectedRange: NSRange())

        textField.handleInputModeDidChange()

        XCTAssertEqual(textField.text, "www.wikipedia.com")
    }

    func testHandleInputModeDidChange_withLastMarkedText_updatesTextAndSetsMarkedText() {
        textField.text = "www.wiki"
        textField.setMarkedText("pedia.com", selectedRange: NSRange())

        textField.handleInputModeDidChange()

        XCTAssertTrue(textField.text?.contains("www.wiki") ?? false)
        XCTAssertNotNil(textField.markedTextRange)
    }

    func testAutocompleteSuggestion_whenInsertingAtStartOfText_appendsSuggestionAtEnd() {
        // Start with "o" already in the text field.
        makeTextFieldEditing()
        textField.text = "o"

        // Move the cursor before the "o": |o
        if let startPosition = textField.position(from: textField.beginningOfDocument, offset: 0) {
            textField.selectedTextRange = textField.textRange(from: startPosition, to: startPosition)
        }

        // Simulate the user typing "y" at the start.
        _ = textField.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 0, length: 0),
            replacementString: "y"
        )

        textField.text = "yo"
        if let cursorPosition = textField.position(from: textField.beginningOfDocument, offset: 1) {
            textField.selectedTextRange = textField.textRange(from: cursorPosition, to: cursorPosition)
        }

        // Apply the autocomplete suggestion.
        textField.setAutocompleteSuggestion("youtube.com")

        // It should complete the full text, not insert the suggestion after the cursor.
        XCTAssertEqual(textField.text,
                       "youtube.com",
                       "Suggestion should be appended at end of text, not inserted at cursor position")
    }

    func testAutocompleteSuggestion_whenAppendingAtEnd_stillWorks() {
        makeTextFieldEditing()
        textField.text = "yo"

        if let endPosition = textField.position(from: textField.beginningOfDocument, offset: 2) {
            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        }

        _ = textField.textField(
            textField,
            shouldChangeCharactersIn: NSRange(location: 2, length: 0),
            replacementString: "u"
        )

        textField.text = "you"
        if let endPosition = textField.position(from: textField.beginningOfDocument, offset: 3) {
            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        }

        textField.setAutocompleteSuggestion("youtube.com")

        XCTAssertEqual(textField.text, "youtube.com")
    }

    func testApplyTheme_refreshesMarkedText() {
        textField.text = "github"
        // Move cursor to end of text before setting marked text
        if let endPosition = textField.position(from: textField.beginningOfDocument, offset: textField.text!.count-1) {
            textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
        }
        textField.setMarkedText(".com", selectedRange: .init())

        XCTAssertNotNil(textField.markedTextRange, "Marked text should exist before theme change.")

        themeManager.setManualTheme(to: .dark)
        textField.applyTheme(theme: themeManager.getCurrentTheme(for: .XCTestDefaultUUID))

        XCTAssertNotNil(textField.markedTextRange, "Marked text should still exist after theme change.")

        XCTAssertEqual(textField.text, "github.com")
    }
}
