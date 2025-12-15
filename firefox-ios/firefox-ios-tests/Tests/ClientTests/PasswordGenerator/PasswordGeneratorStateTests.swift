// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class PasswordGeneratorStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
    func testUpdateGeneratedPassword() {
        let initialState = createSubject()
        let reducer = passwordGeneratorReducer()

        XCTAssertEqual(initialState.password, "")

        let action = PasswordGeneratorAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: PasswordGeneratorActionType.updateGeneratedPassword,
            password: "abc")
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.password, "abc")
    }

    // MARK: - Private
    private func createSubject() -> PasswordGeneratorState {
        return PasswordGeneratorState(windowUUID: .XCTestDefaultUUID)
    }

    private func passwordGeneratorReducer() -> Reducer<PasswordGeneratorState> {
        return PasswordGeneratorState.reducer
    }
}
