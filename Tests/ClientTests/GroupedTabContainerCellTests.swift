// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class GroupedTabContainerCellTests: XCTestCase {
    func testGroupedTabContainerCell_hasNoLeaks() throws {
        let cell = GroupedTabContainerCell()
        let delegate = MockGroupedTabsDelegate()
        cell.delegate = delegate
        trackForMemoryLeaks(cell)
    }
}

class MockGroupedTabsDelegate: GroupedTabsDelegate {
    func didSelectGroupedTab(tab: Client.Tab?) {}
    func closeTab(tab: Client.Tab) {}
    func performSearchOfGroupInNewTab(searchTerm: String?) {}
}
