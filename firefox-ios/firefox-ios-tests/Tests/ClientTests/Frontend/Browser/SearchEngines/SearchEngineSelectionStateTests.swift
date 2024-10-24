// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SearchEngineSelectionStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialization() {
        let initialState = createSubject()

        XCTAssertFalse(initialState.shouldDismiss)
        XCTAssertEqual(initialState.searchEngines, [])
    }

    func testUpdatingCurrentTabInfo() throws {
        let initialState = createSubject()
        let reducer = searchEngineSelectionReducer()

        let expectedResult: [OpenSearchEngine] = [
            try OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia),
            try OpenSearchEngineTests.generateOpenSearchEngine(type: .youtube)
        ]

        XCTAssertEqual(initialState.searchEngines, [])

        let newState = reducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: SearchEngineSelectionActionType.didLoadSearchEngines,
                searchEngines: expectedResult
            )
        )

        XCTAssertEqual(newState.searchEngines, expectedResult)
    }

    // MARK: - Private
    private func createSubject() -> SearchEngineSelectionState {
        return SearchEngineSelectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchEngineSelectionReducer() -> Reducer<SearchEngineSelectionState> {
        return SearchEngineSelectionState.reducer
    }
}
