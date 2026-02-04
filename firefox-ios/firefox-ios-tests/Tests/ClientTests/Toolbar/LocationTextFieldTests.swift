// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

@MainActor
final class LocationTextFieldTests: XCTestCase {
    private var textField: LocationTextField!
    private var themeManager: MockThemeManager!

    override func setUp() async throws {
        try await super.setUp()
        textField = LocationTextField()
        themeManager = MockThemeManager()
    }

    override func tearDown() async throws {
        textField = nil
        themeManager = nil
        try await super.tearDown()
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
