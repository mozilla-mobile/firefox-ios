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
        Glean.shared.enableTestingMode()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testDismissSurveyAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .closeSurvey)
        mockStore.dispatch(action)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.dismissButtonTapped)
    }

    func testPrivacyNoticeTappedAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .tapPrivacyNotice)
        mockStore.dispatch(action)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.privacyNoticeTapped)
    }

    func testSubmitSurveyAction() throws {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

        let action = MicrosurveyAction(
            userSelection: "Neutral",
            windowUUID: .XCTestDefaultUUID,
            actionType: MicrosurveyActionType.submitSurvey
        )
        mockStore.dispatch(action)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.submitButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.submitButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["user_selection"], "Neutral")
    }

    func testConfirmationViewedAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .confirmationViewed)
        mockStore.dispatch(action)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.confirmationShown)
    }

    private func getAction(for actionType: MicrosurveyActionType) -> MicrosurveyMiddlewareAction {
        return MicrosurveyMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
