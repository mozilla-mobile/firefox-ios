// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

class SyncedTabCellTests: XCTestCase {

    func testConfigureSyncTab_hasNoLeaks() {
        let testUrl = URL(string: "www.test.com")!
        let viewModel = SyncedTabCellViewModel(titleText: "Title",
                                               descriptionText: "Description",
                                               url: testUrl)

        let testButton = UIButton(frame: CGRect.zero)
        let syncedTabsShowAllAction = { button in
            XCTAssertEqual(button, testButton)
        }

        let onOpenSyncedTabAction = { url in
            XCTAssertEqual(url, testUrl)
        }

        let sut = SyncedTabCell(frame: CGRect.zero)
        trackForMemoryLeaks(sut)

        sut.configure(viewModel: viewModel,
                      onTapShowAllAction: syncedTabsShowAllAction,
                      onOpenSyncedTabAction: onOpenSyncedTabAction)

        sut.showAllSyncedTabs(sender: testButton)
        sut.didTapSyncedTab(UITapGestureRecognizer())
    }
}
