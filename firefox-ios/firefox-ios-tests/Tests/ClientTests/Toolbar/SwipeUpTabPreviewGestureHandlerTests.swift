// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class SwipeUpTabPreviewGestureHandlerTests: XCTestCase {
    private var profile: MockProfile!
    private var tabManager: MockTabManager!
    private var mockVC: MockBrowserViewController!
    private var themeManager: MockThemeManager!
    private var mockFlags: MockNimbusFeatureFlags!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        profile = MockProfile()
        tabManager = MockTabManager()
        mockVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        themeManager = MockThemeManager()
        mockFlags = MockNimbusFeatureFlags()
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        mockVC = nil
        themeManager = nil
        mockFlags = nil
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

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> SwipeUpTabPreviewGestureHandler {
        let provider = SwipeGestureFeatureFlagProvider(featureFlagsProvider: mockFlags)
        let tabPreview = SwipeUpTabWebViewPreview(frame: .zero, swipeGestureFeatureFlagProvider: provider)
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
}
