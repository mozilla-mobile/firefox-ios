// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MicrosurveyMiddlewareIntegrationTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func testDismissSurveyAction() throws {
        let subject = createSubject()
        let action = getAction(for: .closeSurvey)

        subject.microsurveyProvider(AppState(), action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.dismissButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.dismissButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MicrosurveyPromptAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MicrosurveyPromptActionType)

        XCTAssertEqual(actionType, MicrosurveyPromptActionType.closePrompt)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func testPrivacyNoticeTappedAction() throws {
        let subject = createSubject()
        let action = getAction(for: .tapPrivacyNotice)

        subject.microsurveyProvider(AppState(), action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.privacyNoticeTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.privacyNoticeTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")

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

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.submitButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.submitButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")
        XCTAssertEqual(resultValue[0].extra?["user_selection"], "Neutral")

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MicrosurveyPromptAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MicrosurveyPromptActionType)

        XCTAssertEqual(actionType, MicrosurveyPromptActionType.closePrompt)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func testConfirmationViewedAction() throws {
        let subject = createSubject()
        let action = getAction(for: .confirmationViewed)

        subject.microsurveyProvider(AppState(), action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.confirmationShown)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.confirmationShown.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")
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
        return MicrosurveyMiddleware()
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
