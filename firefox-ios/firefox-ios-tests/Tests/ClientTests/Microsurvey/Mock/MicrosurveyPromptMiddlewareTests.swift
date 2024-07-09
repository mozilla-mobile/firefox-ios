// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MicrosurveyPromptMiddlewareTests: XCTestCase {
    private var microsurveyManager: MockMicrosurveySurfaceManager!
    override func setUp() {
        super.setUp()
        let model = MicrosurveyModel(
            id: "survey-id",
            promptTitle: "title",
            promptButtonLabel: "button label",
            surveyQuestion: "survey question",
            surveyOptions: [
                "yes",
                "no",
                "maybe"
            ],
            icon: nil,
            utmContent: nil
        )
        microsurveyManager = MockMicrosurveySurfaceManager(with: model)
        DependencyHelperMock().bootstrapDependencies(injectedMicrosurveyManager: microsurveyManager)
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testShowPromptAction_withInvalidModel() {
        DependencyHelperMock().bootstrapDependencies()
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyPromptMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .showPrompt)
        mockStore.dispatch(action)
        XCTAssertEqual(microsurveyManager.handleMessageDisplayedCount, 0)
    }

    func testShowPromptAction_withValidModel() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyPromptMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .showPrompt)
        mockStore.dispatch(action)
        XCTAssertEqual(microsurveyManager.handleMessageDisplayedCount, 1)
    }

    func testClosePromptAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyPromptMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .closePrompt)
        mockStore.dispatch(action)
        XCTAssertEqual(microsurveyManager.handleMessageDismissCount, 1)
    }

    func testContinueToSurveyAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyPromptMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .continueToSurvey)
        mockStore.dispatch(action)
        XCTAssertEqual(microsurveyManager.handleMessagePressedCount, 1)
    }

    private func getAction(for actionType: MicrosurveyPromptActionType) -> MicrosurveyPromptMiddlewareAction {
        return MicrosurveyPromptMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
