// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class TabPeekViewControllerTests: XCTestCase {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testTabPeekViewController_simpleCreation_hasNoLeaks() {
        let tab = TabModel.emptyState(tabUUID: UUID().uuidString, title: "Test Tab")
        let tabPeekViewController = TabPeekViewController(tab: tab, windowUUID: windowUUID)
        trackForMemoryLeaks(tabPeekViewController)
    }
}
