// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MicrosurveyPromptMiddlewareTests: XCTestCase {
    private var microsurveyManager: MockMicrosurveySurfaceManager!
    var mockStore: MockStoreForMiddleware<AppState>!

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
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func testShowPromptAction_withInvalidModel() {
        let subject = createSubject(microsurveyManager: MockMicrosurveySurfaceManager(with: nil))

        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyPromptActionType.showPrompt
        )

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(microsurveyManager.handleMessageDisplayedCount, 0)
    }

    func testShowPromptAction_withValidModel() throws {
        let subject = createSubject(microsurveyManager: microsurveyManager)
        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyPromptActionType.showPrompt
        )

        subject.microsurveyProvider(AppState(), action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MicrosurveyPromptMiddlewareAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MicrosurveyPromptMiddlewareActionType)

        XCTAssertEqual(actionType, MicrosurveyPromptMiddlewareActionType.initialize)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(microsurveyManager.handleMessageDisplayedCount, 1)
    }

    func testClosePromptAction() {
        let subject = createSubject(microsurveyManager: microsurveyManager)
        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyPromptActionType.closePrompt
        )

        subject.microsurveyProvider(AppState(), action)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(microsurveyManager.handleMessageDismissCount, 1)
    }

    func testContinueToSurveyAction() {
        let subject = createSubject(microsurveyManager: microsurveyManager)
        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyPromptActionType.continueToSurvey
        )

        subject.microsurveyProvider(AppState(), action)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(microsurveyManager.handleMessagePressedCount, 1)
    }

    // MARK: - Helpers
    private func createSubject(microsurveyManager: MockMicrosurveySurfaceManager) -> MicrosurveyPromptMiddleware {
        return MicrosurveyPromptMiddleware(microsurveyManager: microsurveyManager)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .microsurvey(
                        MicrosurveyState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
