// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class ZoomBarScreen {
    private let app: XCUIApplication
    private let sel: ZoomBarSelectorsSet

    init(app: XCUIApplication, selectors: ZoomBarSelectorsSet = ZoomBarSelectors()) {
        self.app = app
        self.sel = selectors
    }

    // Elements
    private var zoomInButton: XCUIElement { sel.ZOOM_IN_BUTTON.element(in: app) }
    private var zoomOutButton: XCUIElement { sel.ZOOM_OUT_BUTTON.element(in: app) }
    private var zoomLevelAny: XCUIElement { sel.ZOOM_LEVEL_ANY.element(in: app) }
    private var bookText: XCUIElement { sel.BOOK_OF_MOZILLA_TEXT.element(in: app) }

    @discardableResult
    func tapZoomIn(times: Int = 1, fastTimeout: TimeInterval = 0.8) -> Self {
        for _ in 0..<times { zoomInButton.waitAndTap() }
        return self
    }

    @discardableResult
    func tapZoomOut(times: Int = 1, fastTimeout: TimeInterval = 0.8) -> Self {
        for _ in 0..<times { zoomOutButton.waitAndTap() }
        return self
    }

    func currentZoomPercent() -> String {
        // The label can be StaticText or Button → let's use “any”
        // ex: "Current Zoom Level: 150%"
        let label = zoomLevelAny.label
        if let pct = label.split(separator: " ").last {
            return String(pct)
        }
        return label
    }

    func assertZoomPercent(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(currentZoomPercent(), expected, file: file, line: line)
    }

    func assertBookTextHeightChanged(
        action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let before = bookText.frame.size.height
        action()
        let after = bookText.frame.size.height
        XCTAssertNotEqual(before, after, "Expected book text height to change after action", file: file, line: line)
    }

    func returnBookTextElement() -> XCUIElement {
        return bookText
    }
}
