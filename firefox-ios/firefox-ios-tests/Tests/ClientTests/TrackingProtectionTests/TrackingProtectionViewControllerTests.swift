// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import Client

@MainActor
final class TrackingProtectionViewControllerTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
    }

    override func tearDown() async throws {
        mockProfile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testPanGestureRecognizerAction_changedStateWhenPointOriginIsNil_updatesFrameOriginUsingViewOrigin() {
        let subject = createSubject()
        let initialOrigin = subject.view.frame.origin
        let translationY: CGFloat = 50

        let mockGesture = MockPanGestureRecognizer()
        mockGesture.mockState = .changed
        mockGesture.mockTranslation = CGPoint(x: 0, y: translationY)
        mockGesture.mockVelocity = .zero

        subject.panGestureRecognizerAction(sender: mockGesture)

        XCTAssertEqual(subject.view.frame.origin,
                       CGPoint(x: initialOrigin.x, y: initialOrigin.y + translationY))
    }

    func testPanGestureRecognizerAction_endedStateWhenPointOriginIsNil_restoresFrameToOriginalOrigin() {
        let subject = createSubject()
        let initialOrigin = subject.view.frame.origin

        let mockGesture = MockPanGestureRecognizer()
        mockGesture.mockState = .ended
        mockGesture.mockTranslation = CGPoint(x: 0, y: 20)
        mockGesture.mockVelocity = .zero

        subject.panGestureRecognizerAction(sender: mockGesture)

        XCTAssertEqual(subject.view.frame.origin, initialOrigin)
    }

    // MARK: - Helpers

    private func createSubject() -> TrackingProtectionViewController {
        let model = TrackingProtectionModel(
            userDefaults: nil,
            url: URL(string: "https://example.com")!,
            displayTitle: "example.com",
            connectionSecure: true,
            globalETPIsEnabled: true,
            contentBlockerStatus: .noBlockedURLs,
            contentBlockerStats: nil,
            selectedTab: nil
        )
        return TrackingProtectionViewController(
            viewModel: model,
            profile: mockProfile,
            windowUUID: .XCTestDefaultUUID
        )
    }
}

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
