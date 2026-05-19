// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class EnhancedTrackingProtectionVCTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    /// Regression test: prior to the fix, `panGestureRecognizerAction` force-unwrapped `pointOrigin`,
    /// which is only set inside `viewDidLayoutSubviews`. If the pan gesture fired before the first
    /// layout pass (e.g. after a memory warning or a rapid present/dismiss cycle), the app crashed
    /// with `EXC_BAD_INSTRUCTION`. The handler must now tolerate a nil `pointOrigin`.
    func testPanGestureRecognizerAction_beforeLayoutPass_doesNotCrash() {
        let subject = makeSUT()
        subject.loadViewIfNeeded()
        // Intentionally do NOT call viewDidLayoutSubviews -- pointOrigin stays nil.

        let mockGesture = MockPanGestureRecognizer()
        mockGesture.mockState = .changed
        mockGesture.mockTranslation = CGPoint(x: 0, y: 50)
        mockGesture.mockVelocity = .zero

        subject.panGestureRecognizerAction(sender: mockGesture)

        XCTAssertNotNil(subject.view, "View should still exist after gesture without prior layout pass")
    }

    /// The .ended branch should also be safe when pointOrigin is still nil — both unwrap sites
    /// must handle the nil case consistently.
    func testPanGestureRecognizerAction_endedStateBeforeLayout_doesNotCrash() {
        let subject = makeSUT()
        subject.loadViewIfNeeded()

        let mockGesture = MockPanGestureRecognizer()
        mockGesture.mockState = .ended
        mockGesture.mockTranslation = CGPoint(x: 0, y: 20)
        mockGesture.mockVelocity = .zero

        subject.panGestureRecognizerAction(sender: mockGesture)

        XCTAssertNotNil(subject.view)
    }

    // MARK: - Helpers

    private func makeSUT() -> EnhancedTrackingProtectionMenuVC {
        let viewModel = EnhancedTrackingProtectionMenuVM(
            url: URL(string: "https://example.com")!,
            displayTitle: "example.com",
            connectionSecure: true,
            globalETPIsEnabled: true,
            contentBlockerStatus: .noBlockedURLs
        )
        return EnhancedTrackingProtectionMenuVC(
            viewModel: viewModel,
            windowUUID: .XCTestDefaultUUID
        )
    }
}

/// Test double allowing us to drive the pan gesture handler deterministically.
private final class MockPanGestureRecognizer: UIPanGestureRecognizer {
    var mockState: UIGestureRecognizer.State = .began
    var mockTranslation: CGPoint = .zero
    var mockVelocity: CGPoint = .zero

    init() {
        super.init(target: nil, action: nil)
    }

    override var state: UIGestureRecognizer.State {
        get { mockState }
        set { mockState = newValue }
    }

    override func translation(in view: UIView?) -> CGPoint {
        return mockTranslation
    }

    override func velocity(in view: UIView?) -> CGPoint {
        return mockVelocity
    }
}
