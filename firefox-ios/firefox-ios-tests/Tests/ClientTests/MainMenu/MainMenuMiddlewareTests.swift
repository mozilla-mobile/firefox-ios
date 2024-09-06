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

        let action = getAction(for: .closeMenu)
        mockStore.dispatch(action)
    }

    private func getAction(for actionType: MainMenuActionType) -> MainMenuAction {
        return MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
