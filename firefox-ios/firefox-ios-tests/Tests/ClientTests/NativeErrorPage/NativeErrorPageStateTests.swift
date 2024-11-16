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

    func testLoadErrorpageData() {
        let initialState = createSubject()
        let reducer = NativeErrorPageReducer()

        XCTAssertNil(initialState.title)
        XCTAssertNil(initialState.description)
        XCTAssertNil(initialState.foxImage)
        XCTAssertNil(initialState.url)

        let action = getAction(for: .initialize)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.title, "NoInternetConnection")
        XCTAssertEqual(newState.description, "There’s a problem with your internet connection.")
        XCTAssertEqual(newState.foxImage, "foxLogo")
        XCTAssertEqual(newState.url, URL(string: "url.com"))
    }

    // MARK: - Private
    private func createSubject() -> NativeErrorPageState {
        return NativeErrorPageState(windowUUID: .XCTestDefaultUUID)
    }

    private func NativeErrorPageReducer() -> Reducer<NativeErrorPageState> {
        return NativeErrorPageState.reducer
    }

    private func getAction(for actionType: NativeErrorPageMiddlewareActionType) -> NativeErrorPageAction {
        let model = NativeErrorPageMock.model
        return  NativeErrorPageAction(nativePageErrorModel: model, windowUUID: .XCTestDefaultUUID, actionType: actionType)
    }
}
