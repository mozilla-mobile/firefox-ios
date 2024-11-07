// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MicrosurveyPromptStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testShowPromptAction() {
        let initialState = createSubject()
        let reducer = microsurveyReducer()

        XCTAssertEqual(initialState.showPrompt, false)

        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize
        )
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showPrompt, true)
        XCTAssertEqual(newState.showSurvey, false)
    }

    func testDismissPromptAction() {
        let initialState = MicrosurveyPromptState(
            windowUUID: .XCTestDefaultUUID,
            showPrompt: true,
            showSurvey: false,
            model: MicrosurveyMock.model
        )
        let reducer = microsurveyReducer()

        XCTAssertEqual(initialState.showPrompt, true)

        let action = getAction(for: .closePrompt)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showPrompt, false)
        XCTAssertEqual(newState.showSurvey, false)
    }

    func testShowSurveyAction() {
        let initialState = createSubject()
        let reducer = microsurveyReducer()

        XCTAssertEqual(initialState.showSurvey, false)

        let action = getAction(for: .continueToSurvey)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showSurvey, true)
        XCTAssertEqual(newState.showPrompt, true)
    }

    func testDefaultAction() {
        let initialState = MicrosurveyPromptState(
            windowUUID: .XCTestDefaultUUID,
            showPrompt: true,
            showSurvey: true,
            model: MicrosurveyMock.model
        )
        let reducer = microsurveyReducer()

        let action = getInvalidAction()
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.showPrompt, true)
        XCTAssertEqual(newState.showSurvey, false)
        XCTAssertEqual(newState.model, MicrosurveyMock.model)
    }

    // MARK: - Private
    private func createSubject() -> MicrosurveyPromptState {
        return MicrosurveyPromptState(windowUUID: .XCTestDefaultUUID)
    }

    private func microsurveyReducer() -> Reducer<MicrosurveyPromptState> {
        return MicrosurveyPromptState.reducer
    }

    private func getAction(for actionType: MicrosurveyPromptActionType) -> MicrosurveyPromptAction {
        return  MicrosurveyPromptAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }

    private func getInvalidAction() -> MicrosurveyPromptAction {
        return MicrosurveyPromptAction(windowUUID: .XCTestDefaultUUID, actionType: FakeActionType.testAction)
    }

    enum FakeActionType: ActionType {
        case testAction
    }
}
