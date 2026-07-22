// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class SwipeUpTabPreviewGestureHandlerTests: XCTestCase, StoreTestUtility {
    private var profile: MockProfile!
    private var tabManager: MockTabManager!
    private var mockVC: MockBrowserViewController!
    private var themeManager: MockThemeManager!
    private var mockFlags: MockNimbusFeatureFlags!
    private var tabPreview: SwipeUpTabWebViewPreview!
    private var mockStore: MockStoreForMiddleware<AppState>!

    // releaseOutcome thresholds against a 600pt tall preview: close (1/3) y = 200, tabTray (2/3) y = 400.
    private let previewFrame = CGRect(x: 0, y: 0, width: 300, height: 600)

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tabManager = MockTabManager()
        mockVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        themeManager = MockThemeManager()
        mockFlags = MockNimbusFeatureFlags()
        setupStore()
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        mockVC = nil
        themeManager = nil
        mockFlags = nil
        tabPreview = nil
        resetStore()
        mockStore = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - setupGesture

    func testSetupGesture_whenSwipeGestureEnabled_addsSwipeUpAndDownGestures() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTraySwipe]
        let subject = createSubject()
        let view = UIView()

        subject.setupGesture(on: view)

        let swipeGestures = view.gestureRecognizers?.compactMap { $0 as? UISwipeGestureRecognizer } ?? []
        XCTAssertEqual(swipeGestures.count, 2)
        XCTAssertTrue(swipeGestures.contains { $0.direction == .up })
        XCTAssertTrue(swipeGestures.contains { $0.direction == .down })
        XCTAssertNil(view.gestureRecognizers?.first { $0 is UIPanGestureRecognizer })
    }

    func testSetupGesture_whenInteractiveGestureEnabled_addsPanGesture() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        let view = UIView()

        subject.setupGesture(on: view)

        let panGestures = view.gestureRecognizers?.compactMap { $0 as? UIPanGestureRecognizer } ?? []
        XCTAssertEqual(panGestures.count, 1)
        XCTAssertTrue(panGestures.first?.isEnabled ?? false)
        XCTAssertTrue(panGestures.first?.delegate === subject)
        XCTAssertNil(view.gestureRecognizers?.first { $0 is UISwipeGestureRecognizer })
    }

    func testSetupGesture_whenSwipeOverridesInteractive_addsSwipeGesturesOnly() {
        mockFlags.enabledFlags = [
            .addressBarGestureToOpenTabTrayInteractive,
            .addressBarGestureToOpenTabTraySwipe
        ]
        let subject = createSubject()
        let view = UIView()

        subject.setupGesture(on: view)

        XCTAssertEqual(view.gestureRecognizers?.count, 2)
        XCTAssertNil(view.gestureRecognizers?.first { $0 is UIPanGestureRecognizer })
    }

    func testSetupGesture_whenNoGestureEnabled_addsNoGestures() {
        mockFlags.enabledFlags = []
        let subject = createSubject()
        let view = UIView()

        subject.setupGesture(on: view)

        XCTAssertNil(view.gestureRecognizers)
    }

    // MARK: - gestureRecognizerShouldBegin

    func testGestureRecognizerShouldBegin_whenNotPanGesture_returnsFalse() {
        let subject = createSubject()
        let swipeGesture = UISwipeGestureRecognizer()

        XCTAssertFalse(subject.gestureRecognizerShouldBegin(swipeGesture))
    }

    func testGestureRecognizerShouldBegin_whenVerticalVelocityDominates_returnsTrue() {
        let subject = createSubject()
        let panGesture = MockUIPanGestureRecognizer()
        panGesture.gestureVelocity = CGPoint(x: 10, y: 100)

        XCTAssertTrue(subject.gestureRecognizerShouldBegin(panGesture))
    }

    func testGestureRecognizerShouldBegin_whenHorizontalVelocityDominates_returnsFalse() {
        let subject = createSubject()
        let panGesture = MockUIPanGestureRecognizer()
        panGesture.gestureVelocity = CGPoint(x: 100, y: 10)

        XCTAssertFalse(subject.gestureRecognizerShouldBegin(panGesture))
    }

    func testGestureRecognizerShouldBegin_whenVelocitiesAreEqual_returnsFalse() {
        let subject = createSubject()
        let panGesture = MockUIPanGestureRecognizer()
        panGesture.gestureVelocity = CGPoint(x: 50, y: 50)

        XCTAssertFalse(subject.gestureRecognizerShouldBegin(panGesture))
    }

    // MARK: - handlePanGesture

    func testHandlePanGesture_whenInteractiveGestureDisabled_doesNotDispatch() {
        mockFlags.enabledFlags = []
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .ended
        gesture.gestureLocation = CGPoint(x: 150, y: 300)

        subject.handlePanGestureForTesting(gesture)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testHandlePanGesture_whenNoSelectedTab_doesNothing() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        tabManager.selectedTab = nil
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .began

        subject.handlePanGestureForTesting(gesture)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testHandlePanGesture_whenBegan_doesNotDispatch() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .began

        subject.handlePanGestureForTesting(gesture)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testHandlePanGesture_whenChanged_doesNotDispatch() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .changed
        gesture.gestureTranslation = CGPoint(x: 0, y: -150)
        gesture.gestureLocation = CGPoint(x: 150, y: 100)

        subject.handlePanGestureForTesting(gesture)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testHandlePanGesture_whenEndedInBottomThird_cancelsWithoutDispatch() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .ended
        gesture.gestureLocation = CGPoint(x: 150, y: 500)

        subject.handlePanGestureForTesting(gesture)

        XCTAssertTrue(mockStore.dispatchedActions.isEmpty)
    }

    func testHandlePanGesture_whenEndedInMiddle_dispatchesShowTabTray() {
        mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayInteractive]
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .ended
        gesture.gestureLocation = CGPoint(x: 150, y: 300)

        subject.handlePanGestureForTesting(gesture)

        let action = mockStore.dispatchedActions.first { $0 is GeneralBrowserAction } as? GeneralBrowserAction
        XCTAssertEqual(action?.actionType as? GeneralBrowserActionType, .showTabTray)

        // The open tab tray path schedules a delayed dismiss that captures self,
        // do this so the memory leak check doesn't yell at me
        drainDismissDelay()
    }

    func testHandlePanGesture_whenEndedInTopThirdAndCloseTabEnabled_tossesPreviewCard() {
        mockFlags.enabledFlags = [
            .addressBarGestureToOpenTabTrayInteractive,
            .addressBarGestureToOpenTabTrayCloseTab
        ]
        let subject = createSubject()
        tabManager.selectedTab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let gesture = MockSwipeUpPanGestureRecognizer()
        gesture.state = .ended
        gesture.gestureLocation = CGPoint(x: 150, y: 100)

        subject.handlePanGestureForTesting(gesture)

        XCTAssertLessThan(tabPreview.previewCardFrame.midY, previewFrame.midY)
    }

    // MARK: - handleSwipeGesture

    func testHandleSwipeGesture_whenNoToolbarState_dispatchesToolbarMiddlewareAction() {
        let subject = createSubject()
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .up

        subject.handleSwipeGestureForTesting(gesture)

        let action = mockStore.dispatchedActions.first { $0 is ToolbarMiddlewareAction } as? ToolbarMiddlewareAction
        XCTAssertEqual(action?.actionType as? ToolbarMiddlewareActionType, .didSwipeToOpenTabTray)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> SwipeUpTabPreviewGestureHandler {
        let provider = SwipeGestureFeatureFlagProvider(featureFlagsProvider: mockFlags)
        tabPreview = SwipeUpTabWebViewPreview(frame: previewFrame, swipeGestureFeatureFlagProvider: provider)
        tabPreview.layoutIfNeeded()
        let subject = SwipeUpTabPreviewGestureHandler(
            tabPreview: tabPreview,
            bottomBlurView: UIView(),
            topBlurView: UIView(),
            screenshotHelper: ScreenshotHelper(controller: mockVC),
            tabManager: tabManager,
            themeManager: themeManager,
            windowUUID: .XCTestDefaultUUID,
            swipeGestureFeatureFlagProvider: provider
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    /// Spins the run loop long enough for the open-tab-tray dismiss delay (0.4s) to fire,
    /// releasing the strong self capture before the memory leak teardown check runs.
    private func drainDismissDelay() {
        let expectation = XCTestExpectation(description: "dismiss delay elapsed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func setupAppState() -> AppState {
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

// Private subclass so we don't affect other tests that rely on the overridden function
private class MockSwipeUpPanGestureRecognizer: MockUIPanGestureRecognizer {
    var gestureLocation: CGPoint?
    private var stateOverride: UIGestureRecognizer.State?

    // UIKit doesn't persist a forced state on an idle recognizer, so back it with our own storage
    override var state: UIGestureRecognizer.State {
        get { stateOverride ?? super.state }
        set { stateOverride = newValue }
    }

    override func location(in view: UIView?) -> CGPoint {
        if let gestureLocation = gestureLocation {
            return gestureLocation
        }
        return super.location(in: view)
    }
}
