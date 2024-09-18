// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MicrosurveyMiddlewareTests: XCTestCase {
    override func setUp() {
        super.setUp()
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testDismissSurveyAction() throws {
        store = Store(
            state: setupAppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

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
        store = Store(
            state: setupAppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

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
        store = Store(
            state: setupAppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

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
        store = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

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

    private func setupAppState() -> AppState {
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
}
