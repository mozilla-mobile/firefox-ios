// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class StoriesFeedViewControllerTests: XCTestCase {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
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

    func testDeinit_whenRecordTelemetryOnDisappearIsTrue_recordsClosedTelemetry() {
        let telemetry = MockStoriesFeedTelemetry()
        var subject = createNullableSubject(telemetry: telemetry)

        // No-op to prevent "Written to but never read" xcode error
        _ = subject

        subject = nil

        XCTAssertEqual(telemetry.storiesFeedClosedCalled, 1)
    }

    func testDeinit_whenRecordTelemetryOnDisappearIsFalse_doesNotRecordClosedTelemetry() {
        let telemetry = MockStoriesFeedTelemetry()
        var subject = createNullableSubject(telemetry: telemetry)

        subject?.willBeDismissed(reason: .deeplink)

        subject = nil

        XCTAssertEqual(telemetry.storiesFeedClosedCalled, 0)
    }

    private func createSubject(telemetry: StoriesFeedTelemetryProtocol? = nil) -> StoriesFeedViewController {
        let storiesFeedViewController = StoriesFeedViewController(windowUUID: .XCTestDefaultUUID,
                                                                  telemetry: telemetry ?? MockStoriesFeedTelemetry())
        trackForMemoryLeaks(storiesFeedViewController)
        return storiesFeedViewController
    }

    private func createNullableSubject(telemetry: StoriesFeedTelemetryProtocol? = nil) -> StoriesFeedViewController? {
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
