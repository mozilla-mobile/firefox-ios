// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class StoriesFeedViewControllerTests: XCTestCase {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_viewDidLoad_triggersStoriesFeedAction() throws {
        let subject = createSubject()

        subject.viewDidLoad()

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is StoriesFeedAction }) as? StoriesFeedAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? StoriesFeedActionType)
        XCTAssertEqual(actionType, StoriesFeedActionType.initialize)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    private func createSubject(telemetry: StoriesFeedTelemetryProtocol? = nil) -> StoriesFeedViewController {
        let storiesFeedViewController = StoriesFeedViewController(windowUUID: .XCTestDefaultUUID,
                                                                  telemetry: telemetry ?? MockStoriesFeedTelemetry())
        trackForMemoryLeaks(storiesFeedViewController)
        return storiesFeedViewController
    }

    private func createOptionalSubject(telemetry: StoriesFeedTelemetryProtocol? = nil) -> StoriesFeedViewController? {
        let storiesFeedViewController = StoriesFeedViewController(windowUUID: .XCTestDefaultUUID,
                                                                  telemetry: telemetry ?? MockStoriesFeedTelemetry())
        trackForMemoryLeaks(storiesFeedViewController)
        return storiesFeedViewController
    }

    func setupAppState() -> Client.AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
