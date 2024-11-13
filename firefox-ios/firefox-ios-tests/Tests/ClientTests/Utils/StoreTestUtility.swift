// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
@testable import Client

protocol StoreTestUtility {
    func setupAppState() -> AppState
    func setupTestingStore()
    func resetTestingStore()
}

/// Utility class used when replacing the global store for testing purposes
class StoreTestUtilityHelper {
    static func setupTestingStore(with appState: AppState, middlewares: [Middleware<AppState>]) {
        store = Store(
            state: appState,
            reducer: AppState.reducer,
            middlewares: middlewares
        )
    }

    static func setupTestingStore(with mockStore: any DefaultDispatchStore<AppState>) {
        store = mockStore
    }

    /// In order to avoid flaky tests, we should reset the store similar to production
    static func resetTestingStore() {
        store = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: middlewares
        )
    }
}
