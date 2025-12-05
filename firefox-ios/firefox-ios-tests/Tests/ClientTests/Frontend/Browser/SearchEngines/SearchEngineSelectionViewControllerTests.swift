// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common

@testable import Client

@MainActor
final class SearchEngineSelectionViewControllerTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private var mockCoordinator: MockSearchEngineSelectionCoordinator!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockCoordinator = MockSearchEngineSelectionCoordinator()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testSearchEngineSelectionViewController_simpleCreation_hasNoLeaks() {
        let controller = SearchEngineSelectionViewController(windowUUID: windowUUID)
        trackForMemoryLeaks(controller)
    }

    func testDidTapOpenSettings_callsCoordinatorShowSettings() {
        let controller = SearchEngineSelectionViewController(windowUUID: windowUUID)
        controller.coordinator = mockCoordinator

        controller.didTapOpenSettings()

        XCTAssertEqual(mockCoordinator.navigateToSearchSettingsCalled, 1)
    }

    func testPresentationControllerDidDismiss_callsCoordinatorDismissModal() {
        let controller = SearchEngineSelectionViewController(windowUUID: windowUUID)
        controller.coordinator = mockCoordinator

        controller.didTapOpenSettings()

        XCTAssertEqual(mockCoordinator.navigateToSearchSettingsCalled, 1)
    }
}
