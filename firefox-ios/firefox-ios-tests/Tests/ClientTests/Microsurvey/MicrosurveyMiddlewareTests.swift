// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MicrosurveyMiddlewareIntegrationTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockMicrosurveyTelemetry: MockMicrosurveyTelemetry!

    override func setUp() async throws {
        try await super.setUp()
        mockMicrosurveyTelemetry = MockMicrosurveyTelemetry()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        mockMicrosurveyTelemetry = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func testDismissSurveyAction() throws {
        let subject = createSubject()
        let action = getAction(for: .closeSurvey)

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockMicrosurveyTelemetry.lastSurveyId, "microsurvey-id")
        XCTAssertEqual(mockMicrosurveyTelemetry.dismissButtonTappedCalledCount, 1)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MicrosurveyPromptAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MicrosurveyPromptActionType)

        XCTAssertEqual(actionType, MicrosurveyPromptActionType.closePrompt)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func testPrivacyNoticeTappedAction() throws {
        let subject = createSubject()
        let action = getAction(for: .tapPrivacyNotice)

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockMicrosurveyTelemetry.lastSurveyId, "microsurvey-id")
        XCTAssertEqual(mockMicrosurveyTelemetry.privacyNoticeTappedCalledCount, 1)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func testSubmitSurveyAction() throws {
        let subject = createSubject()
        let action = MicrosurveyAction(
            surveyId: "microsurvey-id",
            userSelection: "Neutral",
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyActionType.submitSurvey
        )

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockMicrosurveyTelemetry.lastSurveyId, "microsurvey-id")
        XCTAssertEqual(mockMicrosurveyTelemetry.lastUserSelection, "Neutral")
        XCTAssertEqual(mockMicrosurveyTelemetry.userResponseSubmittedCalledCount, 1)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MicrosurveyPromptAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MicrosurveyPromptActionType)

        XCTAssertEqual(actionType, MicrosurveyPromptActionType.closePrompt)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func testSurveyDidAppearAction() throws {
        let subject = createSubject()
        let action = getAction(for: .surveyDidAppear)

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockMicrosurveyTelemetry.lastSurveyId, "microsurvey-id")
        XCTAssertEqual(mockMicrosurveyTelemetry.surveyViewedCalledCount, 1)
    }

    func testConfirmationViewedAction() throws {
        let subject = createSubject()
        let action = getAction(for: .confirmationViewed)

        subject.microsurveyProvider(AppState(), action)

        XCTAssertEqual(mockMicrosurveyTelemetry.lastSurveyId, "microsurvey-id")
        XCTAssertEqual(mockMicrosurveyTelemetry.confirmationShownCalledCount, 1)
    }

    private func getAction(for actionType: MicrosurveyActionType) -> MicrosurveyAction {
        return MicrosurveyAction(
            surveyId: "microsurvey-id",
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }

    // MARK: - Helpers
    private func createSubject() -> MicrosurveyMiddleware {
        return MicrosurveyMiddleware(microsurveyTelemetry: mockMicrosurveyTelemetry)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                    .microsurvey(
                        MicrosurveyState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
