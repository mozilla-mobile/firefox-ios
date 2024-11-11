// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MicrosurveyMiddlewareIntegrationTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
        setupTestingStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetTestingStore()
        super.tearDown()
    }

    func testDismissSurveyAction() throws {
        let action = getAction(for: .closeSurvey)
        store.dispatch(action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.dismissButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.dismissButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")

        let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: .XCTestDefaultUUID
        )
        XCTAssertNotNil(bvcState)
        XCTAssertEqual(bvcState?.microsurveyState.showPrompt, false)
    }

    func testPrivacyNoticeTappedAction() throws {
        let action = getAction(for: .tapPrivacyNotice)
        store.dispatch(action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.privacyNoticeTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.privacyNoticeTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")

        let microsurveyState = store.state.screenState(
            MicrosurveyState.self,
            for: .microsurvey,
            window: .XCTestDefaultUUID
        )
        XCTAssertNotNil(microsurveyState)
        XCTAssertEqual(microsurveyState?.showPrivacy, true)
    }

    func testSubmitSurveyAction() throws {
        let action = MicrosurveyAction(
            surveyId: "microsurvey-id",
            userSelection: "Neutral",
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyActionType.submitSurvey
        )
        store.dispatch(action)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.submitButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.submitButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")
        XCTAssertEqual(resultValue[0].extra?["user_selection"], "Neutral")

        let bvcState = store.state.screenState(
            BrowserViewControllerState.self,
            for: .browserViewController,
            window: .XCTestDefaultUUID
        )
        XCTAssertNotNil(bvcState)
        XCTAssertEqual(bvcState?.microsurveyState.showPrompt, false)
    }

    func testConfirmationViewedAction() throws {
        let action = getAction(for: .confirmationViewed)
        store.dispatch(action)

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

    func setupTestingStore() {
        storeUtilityHelper.setupTestingStore(
            with: setupAppState(),
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetTestingStore() {
        storeUtilityHelper.resetTestingStore()
    }
}
