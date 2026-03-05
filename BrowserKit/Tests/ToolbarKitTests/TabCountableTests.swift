// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import ToolbarKit

@MainActor
final class TabCountableTests: XCTestCase {
    private var button: TabNumberButton!
    private let tabsButtonLargeContentTitle = "Tabs open: "
    private let tabsButtonOverflowLargeContentTitle = "Tabs open: 99+"

    override func setUp() async throws {
        try await super.setUp()
        button = TabNumberButton()
    }

    override func tearDown() async throws {
        button = nil
        try await super.tearDown()
    }

    func testUpdateTabCount_withNormalCount_returnsCountString() {
        let numOfTabs = 5
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonLargeContentTitle + numOfTabs.description)
        let result = button.updateTabCount(for: element)

        XCTAssertEqual(result, "5")
    }

    func testUpdateTabCount_withZeroTabs_clampsToOne() {
        let numOfTabs = 1
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonLargeContentTitle + numOfTabs.description)
        let result = button.updateTabCount(for: element)

        XCTAssertEqual(result, "1")
    }

    func testUpdateTabCount_atMaxCount_returnsMaxString() {
        let numOfTabs = 99
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonLargeContentTitle + numOfTabs.description)
        let result = button.updateTabCount(for: element)

        XCTAssertEqual(result, "99")
    }

    func testUpdateTabCount_exceedingMaxCount_returnsInfinitySymbol() {
        let numOfTabs = 100
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonOverflowLargeContentTitle + numOfTabs.description)
        let result = button.updateTabCount(for: element)

        XCTAssertEqual(result, "\u{221E}")
    }

    // MARK: - Nil Inputs
    func testUpdateTabCount_withNilNumberOfTabs_returnsNil() {
        let element = makeElement(numberOfTabs: nil, largeContentTitle: tabsButtonLargeContentTitle)
        let result = button.updateTabCount(for: element)

        XCTAssertNil(result)
    }

    func testUpdateTabCount_withNilLargeContentTitle_returnsNil() {
        let element = makeElement(numberOfTabs: 5, largeContentTitle: nil)
        let result = button.updateTabCount(for: element)

        XCTAssertNil(result)
    }

    func testUpdateTabCount_withBothNil_returnsNil() {
        let element = makeElement(numberOfTabs: nil, largeContentTitle: nil)
        let result = button.updateTabCount(for: element)

        XCTAssertNil(result)
    }

    // MARK: - Side Effects
    func testUpdateTabCount_updatesAccessibilityValue() {
        let numOfTabs = 7
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonLargeContentTitle + numOfTabs.description)
        button.updateTabCount(for: element)

        XCTAssertEqual(button.accessibilityValue, "7")
    }

    func testUpdateTabCount_updatesLargeContentTitle() {
        let numOfTabs = 3
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonLargeContentTitle + numOfTabs.description)
        button.updateTabCount(for: element)

        XCTAssertEqual(button.largeContentTitle, "Tabs open: 3")
    }

    func testUpdateTabCount_updatesOverflowLargeContentTitle() {
        let numOfTabs = 101
        let element = makeElement(numberOfTabs: numOfTabs,
                                  largeContentTitle: tabsButtonOverflowLargeContentTitle)
        button.updateTabCount(for: element)

        XCTAssertEqual(button.largeContentTitle, "Tabs open: 99+")
    }

    func testUpdateTabCount_withNilInputs_doesNotUpdateAccessibilityValue() {
        button.accessibilityValue = "original"
        let element = makeElement(numberOfTabs: nil, largeContentTitle: nil)
        button.updateTabCount(for: element)

        XCTAssertEqual(button.accessibilityValue, "original")
    }

    // MARK: - Helper
    private func makeElement(numberOfTabs: Int?, largeContentTitle: String?) -> ToolbarElement {
        return ToolbarElement(
            numberOfTabs: numberOfTabs,
            isEnabled: true,
            largeContentTitle: largeContentTitle,
            a11yLabel: "Tabs",
            a11yHint: nil,
            a11yId: "testTabCountButton",
            hasLongPressAction: false,
            onSelected: nil
        )
    }
}
