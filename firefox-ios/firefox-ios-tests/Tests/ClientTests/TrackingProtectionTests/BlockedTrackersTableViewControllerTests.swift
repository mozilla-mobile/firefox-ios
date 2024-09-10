// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

class BlockedTrackersTableViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    let blockedTrackersMockModel = BlockedTrackersTableModel(
        topLevelDomain: "test.com",
        title: "test.com",
        URL: "test.com",
        contentBlockerStats: TPPageStats(),
        connectionSecure: true
    )

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testBlockedTrackersViewController_simpleCreation_hasNoLeaks() {
        let blockedTrackersViewController = BlockedTrackersTableViewController(
            with: blockedTrackersMockModel,
            windowUUID: windowUUID
        )
        trackForMemoryLeaks(blockedTrackersViewController)
    }
}
