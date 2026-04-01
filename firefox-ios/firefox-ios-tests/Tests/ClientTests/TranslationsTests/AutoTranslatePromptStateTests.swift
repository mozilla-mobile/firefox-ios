// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class AutoTranslatePromptStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Reducer Tests

    @MainActor
    func test_showAutoTranslatePrompt_setsShowPromptTrue() {
        let initialState = createSubject()
        let reducer = autoTranslatePromptReducer()

        XCTAssertFalse(initialState.showPrompt)

        let newState = reducer(initialState, getAction(for: .showAutoTranslatePrompt))

        XCTAssertTrue(newState.showPrompt)
    }

    @MainActor
    func test_didTapEnableAutoTranslate_setsShowPromptFalse() {
        let initialState = AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID, showPrompt: true)
        let reducer = autoTranslatePromptReducer()

        XCTAssertTrue(initialState.showPrompt)

        let newState = reducer(initialState, getAction(for: .didTapEnableAutoTranslate))

        XCTAssertFalse(newState.showPrompt)
    }

    @MainActor
    func test_didDismissAutoTranslatePrompt_setsShowPromptFalse() {
        let initialState = AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID, showPrompt: true)
        let reducer = autoTranslatePromptReducer()

        XCTAssertTrue(initialState.showPrompt)

        let newState = reducer(initialState, getAction(for: .didDismissAutoTranslatePrompt))

        XCTAssertFalse(newState.showPrompt)
    }

    @MainActor
    func test_unknownAction_preservesState() {
        let initialState = AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID, showPrompt: true)
        let reducer = autoTranslatePromptReducer()

        let action = TranslationsAction(windowUUID: .XCTestDefaultUUID, actionType: FakeActionType.testAction)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showPrompt, true)
    }

    @MainActor
    func test_actionWithDifferentWindowUUID_preservesState() {
        let initialState = AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID, showPrompt: false)
        let reducer = autoTranslatePromptReducer()

        let action = TranslationsAction(windowUUID: WindowUUID(), actionType: TranslationsActionType.showAutoTranslatePrompt)
        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.showPrompt)
    }

    // MARK: - Private

    private func createSubject() -> AutoTranslatePromptState {
        return AutoTranslatePromptState(windowUUID: .XCTestDefaultUUID)
    }

    private func autoTranslatePromptReducer() -> Reducer<AutoTranslatePromptState> {
        return AutoTranslatePromptState.reducer
    }

    private func getAction(for actionType: TranslationsActionType) -> TranslationsAction {
        return TranslationsAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    enum FakeActionType: ActionType {
        case testAction
    }
}
