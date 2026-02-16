// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SearchEngineSelectionStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testInitialization() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.searchEngines, [])
    }

    @MainActor
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

    @MainActor
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
