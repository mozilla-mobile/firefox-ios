// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

final class BrowserAddressToolbarTests: XCTestCase {
    private var sut: BrowserAddressToolbar?
    private var toolbarElement: ToolbarElement?
    private var toolbarElement2: ToolbarElement?

    override func setUp() {
        super.setUp()
        sut = BrowserAddressToolbar()

        toolbarElement = ToolbarElement(
            iconName: "icon",
            isEnabled: true,
            isSelected: false,
            a11yLabel: "Test Button",
            a11yHint: nil,
            a11yId: "a11yID-1",
            a11yCustomActionName: nil,
            a11yCustomAction: nil,
            hasLongPressAction: false,
            onSelected: nil,
            onLongPress: nil
        )

        toolbarElement2 = ToolbarElement(
            iconName: "icon2",
            isEnabled: true,
            isSelected: false,
            a11yLabel: "Test Button2",
            a11yHint: nil,
            a11yId: "a11yID-2",
            a11yCustomActionName: nil,
            a11yCustomAction: nil,
            hasLongPressAction: false,
            onSelected: nil,
            onLongPress: nil
        )
    }

    override func tearDown() {
        sut = nil
        toolbarElement = nil
        toolbarElement2 = nil
        super.tearDown()
    }

    func testGetToolbarButton_CreatesAndReturnsTheCachedButton() {
        // First call to getToolbarButton should create a new button
        guard let toolbarElement else { return }
        let button1 = sut?.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button1, "Button should not be nil.")

        // Second call to getToolbarButton should return the cached button
        let button2 = sut?.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button2, "Button should not be nil.")

        // Verify that the same button instance is returned
        XCTAssertEqual(button1, button2, "The button should be cached and reused.")

        // Verify the cache count
        XCTAssertEqual(sut?.cachedButtonReferences.count, 1, "Cache should contain one button.")
    }

    func testGetToolbarButton_CreatesNewButtonForDifferentElements() {
        guard let toolbarElement, let toolbarElement2 else { return }
        // First call to getToolbarButton should create a new button for the first element
        let button1 = sut?.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button1, "Button should not be nil.")

        // First call to getToolbarButton should create a new button for the second element
        let button2 = sut?.getToolbarButton(for: toolbarElement2)
        XCTAssertNotNil(button2, "Button should not be nil.")

        // Verify that different button instances are returned for different elements
        XCTAssertNotEqual(button1, button2, "Different button instances should be created for different elements.")

        // Verify the cache count
        XCTAssertEqual(sut?.cachedButtonReferences.count, 2, "Cache should contain two buttons.")
    }
}
