// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
import TestKit
@testable import ToolbarKit

final class BrowserAddressToolbarTests: XCTestCase {
    private var toolbarElement: ToolbarElement?
    private var toolbarElement2: ToolbarElement?
    private var tabToolbarElement: ToolbarElement?

    override func setUp() {
        super.setUp()

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
        toolbarElement = nil
        toolbarElement2 = nil
        tabToolbarElement = nil
        super.tearDown()
    }

    @MainActor
    func testGetToolbarButton_CreatesAndReturnsTheCachedButton() {
        let sut = createSubject()
        // First call to getToolbarButton should create a new button
        guard let toolbarElement else {
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

    @MainActor
    func testGetToolbarButton_CreatesNewButtonForDifferentElements() {
        let sut = createSubject()
        guard let toolbarElement, let toolbarElement2 else {
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

    @MainActor
    func testCacheKeyGeneration() {
        let sut = createSubject()
        guard let toolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let cacheKey = toolbarElement.a11yId
        _ = sut.getToolbarButton(for: toolbarElement)
        XCTAssertTrue(sut.cachedButtonReferences.keys.contains(cacheKey),
                      "Cache should contain key for the toolbar element.")
    }

    @MainActor
    func testTabNumberButtonCreation() {
        let sut = createSubject()
        guard let tabToolbarElement else {
            XCTFail("Setup failed")
            return
        }

        let button = sut.getToolbarButton(for: tabToolbarElement)
        XCTAssertTrue(button is TabNumberButton, "Should create TabNumberButton when numberOfTabs is provided.")
    }

    // MARK: - updateActionStack
    @MainActor
    func testUpdateActionStack_KeepsSameArrangementWhenElementsUnchanged() {
        let sut = createSubject()
        let stackView = UIStackView()
        guard let toolbarElement, let toolbarElement2 else {
            XCTFail("Setup failed.")
            return
        }

        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement, toolbarElement2])
        let firstArrangement = stackView.arrangedSubviews
        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement, toolbarElement2])

        XCTAssertEqual(stackView.arrangedSubviews.count, 2, "Stack should still hold both buttons.")
        XCTAssertTrue(stackView.arrangedSubviews.elementsEqual(firstArrangement) { $0 === $1 },
                      "Reconfiguring with the same elements should leave the arrangement untouched.")
    }

    @MainActor
    func testUpdateActionStack_UpdatesArrangementWhenElementsChange() {
        let sut = createSubject()
        let stackView = UIStackView()
        guard let toolbarElement, let toolbarElement2 else {
            XCTFail("Setup failed.")
            return
        }

        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement])
        XCTAssertEqual(stackView.arrangedSubviews.count, 1, "Stack should hold the single button.")

        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement, toolbarElement2])

        XCTAssertEqual(stackView.arrangedSubviews.count, 2, "Stack should be rebuilt when the elements change.")
        XCTAssertTrue(stackView.arrangedSubviews.last === sut.getToolbarButton(for: toolbarElement2),
                      "The newly added element's button should be last in the stack.")
    }

    @MainActor
    func testUpdateActionStack_RebuildsWhenElementOrderChanges() {
        let sut = createSubject()
        let stackView = UIStackView()
        guard let toolbarElement, let toolbarElement2 else {
            XCTFail("Setup failed")
            return
        }

        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement, toolbarElement2])
        sut.updateActionStack(stackView: stackView, toolbarElements: [toolbarElement2, toolbarElement])

        XCTAssertTrue(stackView.arrangedSubviews.first === sut.getToolbarButton(for: toolbarElement2),
                      "Reordering the elements should reorder the stack.")
    }

    // MARK: Test helper
    @MainActor
    func createSubject(file: StaticString = #filePath, line: UInt = #line) -> BrowserAddressToolbar {
        let subject = BrowserAddressToolbar()
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
