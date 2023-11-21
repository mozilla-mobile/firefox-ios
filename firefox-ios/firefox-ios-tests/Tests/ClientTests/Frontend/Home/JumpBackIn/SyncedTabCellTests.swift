// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Common
import Shared
import XCTest

class SyncedTabCellTests: XCTestCase {
    func testConfigureSyncTab_hasNoLeaks() {
        let testUrl = URL(string: "www.test.com")!

        let viewModel = SyncedTabCellViewModel(
            profile: MockProfile(),
            titleText: "Title",
            descriptionText: "Description",
            url: testUrl
        )

        var wasShowAllActionCalled = false
        let syncedTabsShowAllAction = {
            wasShowAllActionCalled = true
        }

        let onOpenSyncedTabAction = { url in
            XCTAssertEqual(url, testUrl)
        }

        let subject = SyncedTabCell(frame: CGRect.zero)
        trackForMemoryLeaks(subject)

        subject.configure(viewModel: viewModel,
                          theme: LightTheme(),
                          onTapShowAllAction: syncedTabsShowAllAction,
                          onOpenSyncedTabAction: onOpenSyncedTabAction)

        subject.showAllSyncedTabs(UIButton(frame: CGRect.zero))
        XCTAssertTrue(wasShowAllActionCalled)
        subject.didTapSyncedTab(UITapGestureRecognizer())
    }
}
