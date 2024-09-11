// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

final class LegacyGridTabViewControllerTests: XCTestCase {
    private var manager: TabManager!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        manager = TabManagerImplementation(profile: profile,
                                           uuid: ReservedWindowUUID(uuid: .XCTestDefaultUUID, isNew: false))
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        profile = nil
        manager = nil
    }

    func testGridTabViewControllerDeinit() {
        let subject = LegacyGridTabViewController(tabManager: manager, profile: profile)
        trackForMemoryLeaks(subject)
    }
}
