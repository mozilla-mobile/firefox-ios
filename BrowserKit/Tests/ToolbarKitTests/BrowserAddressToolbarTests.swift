// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

final class BrowserAddressToolbarTests: XCTestCase {
    private var sut: BrowserAddressToolbar?
    private var toolbarElement: ToolbarElement?
    private var toolbarElement2: ToolbarElement?
    private var tabToolbarElement: ToolbarElement?

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

        tabToolbarElement = ToolbarElement(
            iconName: "icon",
            numberOfTabs: 5,
            isEnabled: true,
            isSelected: false,
            a11yLabel: "Tab Button",
            a11yHint: nil,
            a11yId: "a11yID-3",
            a11yCustomActionName: nil,
            a11yCustomAction: nil,
            hasLongPressAction: false,
            onSelected: nil,
            onLongPress: nil
        )
    }

    override func tearDown() {
        sut?.cachedButtonReferences.removeAll()
        sut = nil
        toolbarElement = nil
        toolbarElement2 = nil
        tabToolbarElement = nil
        super.tearDown()
    }

    func testGetToolbarButton_CreatesAndReturnsTheCachedButton() {
        // First call to getToolbarButton should create a new button
        guard let sut, let toolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let button1 = sut.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button1, "Button should not be nil.")

        // Second call to getToolbarButton should return the cached button
        let button2 = sut.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button2, "Button should not be nil.")

        // Verify that the same button instance is returned
        XCTAssertTrue(button1 === button2, "The same button instance should be returned from cache.")

        // Verify the cache count
        XCTAssertEqual(sut.cachedButtonReferences.count, 1, "Cache should contain one button.")
    }

    func testGetToolbarButton_CreatesNewButtonForDifferentElements() {
        guard let sut, let toolbarElement, let toolbarElement2 else {
            XCTFail("Setup failed")
            return
        }

        // First call to getToolbarButton should create a new button for the first element
        let button1 = sut.getToolbarButton(for: toolbarElement)
        XCTAssertNotNil(button1, "Button should not be nil.")

        // First call to getToolbarButton should create a new button for the second element
        let button2 = sut.getToolbarButton(for: toolbarElement2)

        XCTAssertNotNil(button1, "First button should not be nil.")
        XCTAssertNotNil(button2, "Second button should not be nil.")
        XCTAssertFalse(button1 === button2, "Different button instances should be created for different elements.")
        XCTAssertEqual(sut.cachedButtonReferences.count, 2, "Cache should contain exactly two buttons.")
    }

    func testGetToolbarButton_WithDifferentConfigurations() {
        guard let sut, let toolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let plainButton = sut.getToolbarButton(for: toolbarElement, buttonConfiguration: .plain())
        let filledButton = sut.getToolbarButton(for: toolbarElement, buttonConfiguration: .filled())

        XCTAssertNotNil(plainButton, "Plain button should not be nil.")
        XCTAssertNotNil(filledButton, "Filled button should not be nil.")
        XCTAssertFalse(plainButton === filledButton, "Different configurations should create different button instances.")
        XCTAssertEqual(sut.cachedButtonReferences.count, 2, "Cache should contain buttons for different configurations.")
    }

    func testCacheKeyGeneration() {
        guard let sut, let toolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let buttonConfiguration: UIButton.Configuration = .filled()
        let cacheKey = "\(toolbarElement.a11yId)-\(buttonConfiguration.hashValue)"

        _ = sut.getToolbarButton(for: toolbarElement, buttonConfiguration: buttonConfiguration)
        XCTAssertTrue(sut.cachedButtonReferences.keys.contains(cacheKey),
                      "Cache should contain key for the toolbar element.")
    }

    func testTabNumberButtonCreation() {
        guard let sut, let tabToolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let button = sut.getToolbarButton(for: tabToolbarElement)
        XCTAssertTrue(button is TabNumberButton, "Should create TabNumberButton when numberOfTabs is provided.")
    }
}
