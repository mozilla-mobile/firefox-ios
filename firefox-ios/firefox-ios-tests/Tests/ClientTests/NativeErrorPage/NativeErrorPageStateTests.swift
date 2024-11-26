// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class NativeErrorPageStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialState() {
        let initialState = createSubject()

        XCTAssertNil(initialState.title)
        XCTAssertNil(initialState.description)
        XCTAssertNil(initialState.foxImage)
        XCTAssertNil(initialState.url)
    }

    func testLoadErrorpageData() {
        let initialState = createSubject()
        let reducer = nativeErrorPageReducer()

        let mockModel = ErrorPageModel(
            errorTitle: "NoInternetConnection",
            errorDescription: "There’s a problem with your internet connection.",
            foxImageName: "foxLogo",
            url: URL(
                string: "url.com"
            )
        )

        let action = getAction(model: mockModel, for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, mockModel.errorTitle)
        XCTAssertEqual(newState.description, mockModel.errorDescription)
        XCTAssertEqual(newState.foxImage, mockModel.foxImageName)
        XCTAssertEqual(newState.url, mockModel.url)
    }

    // MARK: - Private
    private func createSubject() -> NativeErrorPageState {
        return NativeErrorPageState(windowUUID: .XCTestDefaultUUID)
    }

    private func nativeErrorPageReducer() -> Reducer<NativeErrorPageState> {
        return NativeErrorPageState.reducer
    }

    private func getAction(
        model: ErrorPageModel,
        for actionType: NativeErrorPageMiddlewareActionType
    ) -> NativeErrorPageAction {
        return  NativeErrorPageAction(
            nativePageErrorModel: model,
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
