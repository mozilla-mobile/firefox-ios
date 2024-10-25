// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client
class TabCellTests: XCTestCase {
    var cellDelegate: MockTabCellDelegate!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        cellDelegate = MockTabCellDelegate()
        profile = MockProfile()
    }

    override func tearDown() {
        super.tearDown()
        cellDelegate = nil
        profile = nil
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

    private func createDefaultState() -> TabModel {
        let tabUUID = "0022-22D3"
        return TabModel(tabUUID: tabUUID,
                        isSelected: false,
                        isPrivate: false,
                        isFxHomeTab: false,
                        tabTitle: "Firefox Browser",
                        url: URL(string: "https://www.mozilla.org/en-US/firefox/")!,
                        screenshot: nil,
                        hasHomeScreenshot: false)
    }
}

class MockTabCellDelegate: TabCellDelegate {
    var tabCellClosedCounter = 0

    func tabCellDidClose(for tabUUID: String) {
        tabCellClosedCounter += 1
    }
}
