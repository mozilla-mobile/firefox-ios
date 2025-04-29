// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SearchEngineSelectionMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockProfile: MockProfile!
    var mockSearchEnginesManager: SearchEnginesManagerProvider!
    let mockSearchEngines: [OpenSearchEngine] = [
        OpenSearchEngineTests.generateOpenSearchEngine(type: .wikipedia, withImage: UIImage()),
        OpenSearchEngineTests.generateOpenSearchEngine(type: .youtube, withImage: UIImage()),
    ]
    var mockSearchEngineModels: [SearchEngineModel] {
        return mockSearchEngines.map({ $0.generateModel() })
    }

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        mockSearchEnginesManager = MockSearchEnginesManager(searchEngines: mockSearchEngines)

        // We must reset the global mock store prior to each test
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func testViewDidLoad_dispatchesDidLoadSearchEngines() throws {
        let subject = createSubject(mockSearchEnginesManager: mockSearchEnginesManager)
        let action = getAction(for: .viewDidLoad)

        subject.searchEngineSelectionProvider(AppState(), action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? SearchEngineSelectionAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? SearchEngineSelectionActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, SearchEngineSelectionActionType.didLoadSearchEngines)
        XCTAssertEqual(actionCalled.searchEngines, mockSearchEngineModels)
    }

    func testDidTapSearchEngine_dispatchesDidStartEditingUrl() throws {
        let subject = createSubject(mockSearchEnginesManager: mockSearchEnginesManager)
        let action = getAction(for: .didTapSearchEngine)

        subject.searchEngineSelectionProvider(AppState(), action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.didStartEditingUrl)
    }

    // MARK: - Helpers

    private func createSubject(mockSearchEnginesManager: SearchEnginesManagerProvider) -> SearchEngineSelectionMiddleware {
        return SearchEngineSelectionMiddleware(profile: mockProfile, searchEnginesManager: mockSearchEnginesManager)
    }

    private func getAction(for actionType: SearchEngineSelectionActionType) -> SearchEngineSelectionAction {
        return SearchEngineSelectionAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }

    // MARK: StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .searchEngineSelection(
                        SearchEngineSelectionState(windowUUID: .XCTestDefaultUUID)
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
