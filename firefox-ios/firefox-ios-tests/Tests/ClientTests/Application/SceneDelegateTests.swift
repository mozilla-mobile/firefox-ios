// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class SceneDelegateTests: XCTestCase, FeatureFlaggable {
    private var mockSessionManager: MockAppSessionManager!

    override func setUp() async throws {
        try await super.setUp()
        AppEventQueue.reset()
        DependencyHelperMock().bootstrapDependencies()
        mockSessionManager = MockAppSessionManager()
        setIsDeeplinkOptimizationRefactorEnabled(false)
    }

    override func tearDown() async throws {
        mockSessionManager = nil
        DependencyHelperMock().reset()
        AppEventQueue.reset()
        try await super.tearDown()
    }

    // MARK: - handle(route:) - openedFromExternalSource

    func testHandleRoute_setsOpenedFromExternalSource_synchronously() throws {
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        XCTAssertTrue(mockSessionManager.launchSessionProvider.openedFromExternalSource)
    }

    // MARK: - handle(route:) timing - refactor enabled

    func testHandleRoute_refactorEnabled_dispatchesAfterStartupFlowComplete() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        XCTAssertNotNil(setup.coordinator.savedRoute)
    }

    func testHandleRoute_refactorEnabled_dispatchesWithoutTabRestoration() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()
        // tabRestoration NOT signalled for this coordinator's fresh windowUUID

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        XCTAssertNotNil(setup.coordinator.savedRoute,
                        "With refactor enabled route should dispatch without waiting for tabRestoration")
    }

    func testHandleRoute_refactorEnabled_doesNotDispatch_beforeStartupFlowComplete() throws {
        setIsDeeplinkOptimizationRefactorEnabled(true)
        let setup = try createSubjectWithCoordinator()
        // startupFlowComplete NOT signalled

        let expectation = XCTestExpectation(description: "Route should not dispatch yet")
        expectation.isInverted = true
        AppEventQueue.wait(for: [.startupFlowComplete]) { expectation.fulfill() }

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        wait(for: [expectation], timeout: 0.3)
        XCTAssertNil(setup.coordinator.savedRoute,
                     "With refactor enabled route should not dispatch before startupFlowComplete")
    }

    // MARK: - handle(route:) timing - refactor disabled

    func testHandleRoute_refactorDisabled_doesNotDispatch_withOnlyStartupFlowComplete() throws {
        setIsDeeplinkOptimizationRefactorEnabled(false)
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()
        // tabRestoration NOT signalled for this coordinator's fresh windowUUID

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        XCTAssertNil(setup.coordinator.savedRoute,
                     "With refactor disabled route should wait for tabRestoration too")
    }

    func testHandleRoute_refactorDisabled_dispatchesAfterBothEvents() throws {
        setIsDeeplinkOptimizationRefactorEnabled(false)
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()
        AppEventQueue.signal(event: .tabRestoration(setup.coordinator.windowUUID))

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())

        XCTAssertNotNil(setup.coordinator.savedRoute,
                        "With refactor disabled route should dispatch after both events are signalled")
    }

    func testHandleRoute_refactorDisabled_dispatchesWhenTabRestorationSignalledAfterCall() throws {
        setIsDeeplinkOptimizationRefactorEnabled(false)
        AppEventQueue.signal(event: .startupFlowComplete)
        let setup = try createSubjectWithCoordinator()

        setup.delegate.scene(setup.scene, continue: makeSearchActivity())
        XCTAssertNil(setup.coordinator.savedRoute, "Route should not have dispatched yet")

        AppEventQueue.signal(event: .tabRestoration(setup.coordinator.windowUUID))

        XCTAssertNotNil(setup.coordinator.savedRoute,
                        "Route should dispatch once tabRestoration is signalled")
    }

    // MARK: - Helpers

    private struct TestSubject {
        let delegate: SceneDelegate
        let coordinator: SceneCoordinator
        let scene: UIWindowScene
    }

    private func createSubjectWithCoordinator() throws -> TestSubject {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let coordinator = SceneCoordinator(scene: windowScene,
                                           introManager: MockIntroScreenManager(isModernEnabled: false))
        let delegate = SceneDelegate()
        delegate.sessionManager = mockSessionManager
        delegate.sceneCoordinator = coordinator
        return TestSubject(delegate: delegate, coordinator: coordinator, scene: windowScene)
    }

    private func makeSearchActivity() -> NSUserActivity {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://example.com")
        return activity
    }

    private func setIsDeeplinkOptimizationRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.deeplinkOptimizationRefactorFeature.with { _, _ in
            return DeeplinkOptimizationRefactorFeature(enabled: enabled)
        }
    }
}
