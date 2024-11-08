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

    func testDidLoadSearchEngines() {
        let initialState = createSubject()
        let reducer = searchEngineSelectionReducer()

        let expectedResult = [
            OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage()),
            OpenSearchEngineTests.generateOpenSearchEngine(type: .youtube, withImage: UIImage())
        ].map({ $0.generateModel() })

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
        XCTAssertNil(newState.selectedSearchEngine)
    }

    func testDidTapSearchEngine() {
        let initialState = createSubject()
        let reducer = searchEngineSelectionReducer()

        let selectedSearchEngine = OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage())
                                   .generateModel()

        XCTAssertEqual(initialState.searchEngines, [])
        XCTAssertNil(initialState.selectedSearchEngine)

        let newState = reducer(
            initialState,
            SearchEngineSelectionAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: SearchEngineSelectionActionType.didTapSearchEngine,
                selectedSearchEngine: selectedSearchEngine
            )
        )

        XCTAssertTrue(newState.searchEngines.isEmpty)
        XCTAssertEqual(newState.selectedSearchEngine, selectedSearchEngine)
    }

    // MARK: - Private
    private func createSubject() -> SearchEngineSelectionState {
        return SearchEngineSelectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func searchEngineSelectionReducer() -> Reducer<SearchEngineSelectionState> {
        return SearchEngineSelectionState.reducer
    }
}
