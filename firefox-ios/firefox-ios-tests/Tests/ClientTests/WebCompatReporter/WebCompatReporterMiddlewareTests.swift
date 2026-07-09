// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

@MainActor
final class WebCompatReporterMiddlewareTests: XCTestCase, StoreTestUtility {
    private var mockStore: MockStoreForMiddleware<AppState>!

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

    // MARK: - viewDidLoad

    func test_viewDidLoad_dispatchesDidLoadInitialDraftWithURL() throws {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            url: "https://example.com",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.viewDidLoad
        )

        subject.webCompatReporterProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? WebCompatReporterMiddlewareAction)
        let dispatchedType = try XCTUnwrap(dispatched.actionType as? WebCompatReporterMiddlewareActionType)
        XCTAssertEqual(dispatchedType, WebCompatReporterMiddlewareActionType.didLoadInitialDraft)
        XCTAssertEqual(dispatched.url, "https://example.com")
        subject.webCompatReporterProvider = { _, _ in }
    }

    // MARK: - submit

    func test_submit_doesNotDispatch() {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.submit
        )

        subject.webCompatReporterProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.webCompatReporterProvider = { _, _ in }
    }

    // MARK: - Pure view actions are not handled by the middleware

    func test_selectCategory_doesNotDispatchViaMiddleware() {
        let subject = createSubject()
        let action = WebCompatReporterViewAction(
            category: .siteNotUsable,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        subject.webCompatReporterProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.webCompatReporterProvider = { _, _ in }
    }

    // MARK: - Unrelated action

    func test_unrelatedAction_doesNotDispatch() {
        let subject = createSubject()
        let action = WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        subject.webCompatReporterProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        subject.webCompatReporterProvider = { _, _ in }
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .webCompatReporter(WebCompatReporterState(windowUUID: .XCTestDefaultUUID))
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatReporterMiddleware {
        let subject = WebCompatReporterMiddleware()
        trackForMemoryLeaks(subject)
        return subject
    }
}
