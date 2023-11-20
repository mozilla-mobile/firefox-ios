// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

class TabCellTests: XCTestCase {
    var cellDelegate: MockTabCellDelegate!

    override func setUp() {
        super.setUp()
        cellDelegate = MockTabCellDelegate()
    }

    override func tearDown() {
        super.tearDown()
        cellDelegate = nil
    }

    func testTabCellDeinit() {
        let subject = TabCell(frame: .zero)
        trackForMemoryLeaks(subject)
    }

    func testConfigureTabAXLabel() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate)
        XCTAssert(cell.accessibilityLabel!.contains(state.tabTitle))
    }

    func testConfigureTabAXHint() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate)
        XCTAssertEqual(cell.accessibilityHint!,
                       String.TabTraySwipeToCloseAccessibilityHint)
    }

    func testConfigureTabSelectedState() {
        let cell = TabCell(frame: .zero)
        let state = createDefaultState()
        cell.configure(with: state, theme: nil, delegate: cellDelegate)
        XCTAssertEqual(cell.isSelectedTab,
                       state.isSelected)
    }

    private func createDefaultState() -> TabCellModel {
        return TabCellModel(isSelected: false,
                            isPrivate: false,
                            isFxHomeTab: false,
                            tabTitle: "Firefox Browser",
                            url: URL(string: "https://www.mozilla.org/en-US/firefox/")!,
                            screenshot: nil,
                            hasHomeScreenshot: false,
                            margin: 0.0)
    }
}

class MockTabCellDelegate: TabCellDelegate {
    var tabCellClosedCounter = 0

    func tabCellDidClose(_ cell: TabCell) {
        tabCellClosedCounter += 1
    }
}
