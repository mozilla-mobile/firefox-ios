// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class PocketMiddlewareTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupTestingStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetTestingStore()
        super.tearDown()
    }

//    func testDismissSurveyAction() throws {
//        let action = getAction(for: .closeSurvey)
//        store.dispatch(action)
//
//        testEventMetricRecordingSuccess(metric: GleanMetrics.Microsurvey.dismissButtonTapped)
//        let resultValue = try XCTUnwrap(GleanMetrics.Microsurvey.dismissButtonTapped.testGetValue())
//        XCTAssertEqual(resultValue[0].extra?["survey_id"], "microsurvey-id")
//
//        let bvcState = store.state.screenState(
//            BrowserViewControllerState.self,
//            for: .browserViewController,
//            window: .XCTestDefaultUUID
//        )
//        XCTAssertNotNil(bvcState)
//        XCTAssertEqual(bvcState?.microsurveyState.showPrompt, false)
//    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .homepage(
                        HomepageState(
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
            middlewares: [PocketMiddleware().pocketSectionProvider]
        )
    }

    func resetTestingStore() {
        storeUtilityHelper.resetTestingStore()
    }
}
