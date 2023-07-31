// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class GridTabViewControllerTests: XCTestCase {
    private var manager: TabManager!
    private var profile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        manager = TabManagerImplementation(profile: profile, imageStore: nil)
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
        profile = nil
        manager = nil
    }

    func testGridTabViewControllerDeinit() {
        let subject = GridTabViewController(tabManager: manager, profile: profile)
        trackForMemoryLeaks(subject)
    }
}
