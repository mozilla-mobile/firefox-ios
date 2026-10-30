// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import XCTest

@testable import Client

@MainActor
protocol StoreTestUtility: AnyObject {
    var mockStore: MockStoreForMiddleware<AppState>! { get set }
    func setupAppState() -> AppState
    func setupStore()
    func resetStore()
}

extension StoreTestUtility {
    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        // XCTest keeps test case instances for the whole run; without this the recorded actions outlive the test.
        mockStore = nil
        StoreTestUtilityHelper.resetStore()
    }
}

/// Utility class used when replacing the global store for testing purposes
class StoreTestUtilityHelper {
    @MainActor
    static func setupStore(with appState: AppState, middlewares: [Middleware<AppState>]) {
#if MOCKABLE_STORE
        replaceStore(Store(
            state: appState,
            reducer: AppState.reducer,
            middlewares: middlewares
        ))
#endif
    }
    @MainActor
    static func setupStore(with mockStore: any DefaultDispatchStore<AppState>) {
#if MOCKABLE_STORE
        replaceStore(mockStore)
#endif
    }

    /// In order to avoid flaky tests, we should reset the store similar to production
    @MainActor
    static func resetStore() {
#if MOCKABLE_STORE
        replaceStore(Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: []
        ))
#endif
    }
}
