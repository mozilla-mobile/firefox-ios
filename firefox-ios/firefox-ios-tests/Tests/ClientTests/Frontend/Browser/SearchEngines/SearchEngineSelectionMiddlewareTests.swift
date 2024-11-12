// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class SearchEngineSelectionMiddlewareTests: XCTestCase {
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockProfile: MockProfile!
    var mockSearchEnginesManager: SearchEnginesManager!
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
        mockSearchEnginesManager = SearchEnginesManager(prefs: mockProfile.prefs, files: mockProfile.files)
        mockSearchEnginesManager.orderedEngines = mockSearchEngines

        // We must reset the global mock store prior to each test
        mockStore = MockStoreForMiddleware(state: AppState())
        store = mockStore
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testViewDidLoad_dispatchesDidLoadSearchEngines() throws {
        let subject = createSubject(mockSearchEnginesManager: mockSearchEnginesManager)
        let action = getAction(for: .viewDidLoad)

        subject.searchEngineSelectionProvider(AppState(), action)

        guard let actionCalled = mockStore.dispatchCalled.withActions.first as? SearchEngineSelectionAction,
              case SearchEngineSelectionActionType.didLoadSearchEngines = actionCalled.actionType else {
            XCTFail("Unexpected action type dispatched")
            return
        }
        XCTAssertEqual(mockStore.dispatchCalled.numberOfTimes, 1)
        XCTAssertEqual(actionCalled.searchEngines, mockSearchEngineModels)
    }

    func testDidTapSearchEngine_dispatchesDidStartEditingUrl() throws {
        let subject = createSubject(mockSearchEnginesManager: mockSearchEnginesManager)
        let action = getAction(for: .didTapSearchEngine)

        subject.searchEngineSelectionProvider(AppState(), action)

        guard let actionCalled = mockStore.dispatchCalled.withActions.first as? ToolbarAction,
              case ToolbarActionType.didStartEditingUrl = actionCalled.actionType else {
            XCTFail("Unexpected action type dispatched")
            return
        }
        XCTAssertEqual(mockStore.dispatchCalled.numberOfTimes, 1)
    }

    // MARK: - Helpers

    private func createSubject(mockSearchEnginesManager: SearchEnginesManager) -> SearchEngineSelectionMiddleware {
        return SearchEngineSelectionMiddleware(profile: mockProfile, searchEnginesManager: mockSearchEnginesManager)
    }

    private func getAction(for actionType: SearchEngineSelectionActionType) -> SearchEngineSelectionAction {
        return SearchEngineSelectionAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
