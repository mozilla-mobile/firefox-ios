// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class SwipeUpTabWebViewPreviewTests: XCTestCase {
    private var mockFlags: MockNimbusFeatureFlags!

    // closeReleaseThreshold (1/3) y = 200, tabTrayReleaseThreshold (2/3) y = 400.
    private let frame = CGRect(x: 0, y: 0, width: 300, height: 600)

    override func setUp() {
        super.setUp()
        mockFlags = MockNimbusFeatureFlags()
    }

    override func tearDown() {
        mockFlags = nil
        super.tearDown()
    }

    // MARK: - releaseOutcome

    @MainActor func testReleaseOutcome_whenFingerInTopThirdAndCloseTabEnabled_returnsCloseTab() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 100))

        XCTAssertEqual(outcome, .closeTab)
    }

    @MainActor func testReleaseOutcome_whenFingerInTopThirdAndCloseTabDisabled_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: false)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 100))

        XCTAssertEqual(outcome, .openTabTray)
    }

    @MainActor func testReleaseOutcome_whenFingerAtCloseThresholdAndCloseTabEnabled_returnsCloseTab() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 200))

        XCTAssertEqual(outcome, .closeTab)
    }

    @MainActor func testReleaseOutcome_whenFingerInMiddle_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 300))

        XCTAssertEqual(outcome, .openTabTray)
    }

    @MainActor func testReleaseOutcome_whenFingerAtTabTrayThreshold_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: false)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 400))

        XCTAssertEqual(outcome, .openTabTray)
    }

    @MainActor func testReleaseOutcome_whenFingerInBottomThird_returnsCancel() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 500))

        XCTAssertEqual(outcome, .cancel)
    }

    // MARK: - previewCardFrame

    @MainActor func testPreviewCardFrame_afterLayout_matchesBounds() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.previewCardFrame, subject.bounds)
    }

    // MARK: - Helpers

    @MainActor private func createSubject(frame: CGRect? = nil,
                                          closeTabEnabled: Bool = false,
                                          file: StaticString = #filePath,
                                          line: UInt = #line) -> SwipeUpTabWebViewPreview {
        if closeTabEnabled {
            mockFlags.enabledFlags = [.addressBarGestureToOpenTabTrayCloseTab]
        }
        let provider = SwipeGestureFeatureFlagProvider(featureFlagsProvider: mockFlags)
        let subject = SwipeUpTabWebViewPreview(frame: frame ?? self.frame,
                                               swipeGestureFeatureFlagProvider: provider)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
