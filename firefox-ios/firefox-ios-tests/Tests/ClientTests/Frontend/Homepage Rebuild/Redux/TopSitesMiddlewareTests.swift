// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TopSitesMiddlewareTests: XCTestCase, StoreTestUtility {
    let topSitesManager = MockTopSitesManager()
    var mockStore: MockStoreForMiddleware<AppState>!
    var appState: AppState!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_initializeAction_returnsTopSitesSection() throws {

    }

    // MARK: - Helpers
    private func createSubject(topSitesManager: MockTopSitesManager) -> TopSitesMiddleware {
        return TopSitesMiddleware(topSitesManager: topSitesManager)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        appState = AppState()
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
