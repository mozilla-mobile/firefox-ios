// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MicrosurveyMiddlewareTests: XCTestCase {
    private var microsurveyManager: MockMicrosurveySurfaceManager!
    override func setUp() {
        super.setUp()
        let model = MicrosurveyModel(
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

    func testSubmitSurveyAction() {
        let mockStore = Store(
            state: AppState(),
            reducer: AppState.reducer,
            middlewares: [MicrosurveyMiddleware().microsurveyProvider]
        )

        let action = getAction(for: .submitSurvey)
        mockStore.dispatch(action)
        XCTAssertEqual(microsurveyManager.handleMessagePressedCount, 1)
    }

    private func getAction(for actionType: MicrosurveyActionType) -> MicrosurveyMiddlewareAction {
        return MicrosurveyMiddlewareAction(windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
