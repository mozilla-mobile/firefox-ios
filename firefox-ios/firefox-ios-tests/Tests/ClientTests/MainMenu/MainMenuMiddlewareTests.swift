// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MainMenuMiddlewareTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to puth them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testDismissMenuAction() throws {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MainMenuMiddleware().mainMenuProvider]
        )

        let action = getAction(for: .tapCloseMenu)
        mockStore.dispatch(action)
    }

    private func getAction(for actionType: MainMenuActionType) -> MainMenuAction {
        return MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
