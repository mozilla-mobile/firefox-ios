// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class SwipeUpTabWebViewPreviewTests: XCTestCase {
    private var mockFlags: MockNimbusFeatureFlags!

    // closeReleaseThreshold (1/3) y = 200, tabTrayReleaseThreshold (2/3) y = 400.
    private let frame = CGRect(x: 0, y: 0, width: 300, height: 600)

    override func setUp() async throws {
        try await super.setUp()
        mockFlags = MockNimbusFeatureFlags()
    }

    override func tearDown() async throws {
        mockFlags = nil
        try await super.tearDown()
    }

    // MARK: - releaseOutcome

    func testReleaseOutcome_whenFingerInTopThirdAndCloseTabEnabled_returnsCloseTab() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 100))

        XCTAssertEqual(outcome, .closeTab)
    }

    func testReleaseOutcome_whenFingerInTopThirdAndCloseTabDisabled_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: false)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 100))

        XCTAssertEqual(outcome, .openTabTray)
    }

    func testReleaseOutcome_whenFingerAtCloseThresholdAndCloseTabEnabled_returnsCloseTab() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 200))

        XCTAssertEqual(outcome, .closeTab)
    }

    func testReleaseOutcome_whenFingerInMiddle_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 300))

        XCTAssertEqual(outcome, .openTabTray)
    }

    func testReleaseOutcome_whenFingerAtTabTrayThreshold_returnsOpenTabTray() {
        let subject = createSubject(closeTabEnabled: false)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 400))

        XCTAssertEqual(outcome, .openTabTray)
    }

    func testReleaseOutcome_whenFingerInBottomThird_returnsCancel() {
        let subject = createSubject(closeTabEnabled: true)

        let outcome = subject.releaseOutcome(fingerLocation: CGPoint(x: 150, y: 500))

        XCTAssertEqual(outcome, .cancel)
    }

    // MARK: - previewCardFrame

    func testPreviewCardFrame_afterLayout_matchesBounds() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.previewCardFrame, subject.bounds)
    }

    // MARK: - addTabScreenshot

    func testAddTabScreenshot_doesNotChangeLayout() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        subject.addTabScreenshot(image: UIImage())

        XCTAssertEqual(subject.previewCardFrame, subject.bounds)
    }

    // MARK: - setInitialTransform

    func testSetInitialTransform_whenCloseTabEnabled_showsPreview() {
        let subject = createSubject(closeTabEnabled: true)
        subject.layoutIfNeeded()

        subject.setInitialTransform(topPadding: 50, bottomPadding: 40)

        XCTAssertEqual(subject.alpha, 1.0)
        XCTAssertEqual(subject.layer.zPosition, 1000)
    }

    func testSetInitialTransform_whenCloseTabDisabled_showsPreview() {
        let subject = createSubject(closeTabEnabled: false)
        subject.layoutIfNeeded()

        subject.setInitialTransform(topPadding: 50, bottomPadding: 40)

        XCTAssertEqual(subject.alpha, 1.0)
        XCTAssertEqual(subject.layer.zPosition, 1000)
    }

    // MARK: - translate

    func testTranslate_shrinksPreviewCard() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        subject.translate(CGPoint(x: 0, y: -150), fingerLocation: CGPoint(x: 150, y: 300))

        XCTAssertLessThan(subject.previewCardFrame.width, subject.bounds.width)
    }

    func testTranslate_whenCloseTabEnabledAndFingerInTopThird_shrinksPreviewCard() {
        let subject = createSubject(closeTabEnabled: true)
        subject.layoutIfNeeded()

        subject.translate(CGPoint(x: 0, y: -150), fingerLocation: CGPoint(x: 150, y: 100))

        XCTAssertLessThan(subject.previewCardFrame.width, subject.bounds.width)
    }

    // MARK: - restore

    func testRestore_afterTranslate_resetsPreviewCardFrame() {
        let subject = createSubject()
        subject.layoutIfNeeded()
        subject.translate(CGPoint(x: 0, y: -150), fingerLocation: CGPoint(x: 150, y: 300))

        subject.restore()

        XCTAssertEqual(subject.previewCardFrame, subject.bounds)
    }

    // MARK: - tossPreview

    func testTossPreview_movesPreviewCardUp() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        subject.tossPreview()

        XCTAssertLessThan(subject.previewCardFrame.midY, subject.bounds.midY)
        XCTAssertLessThan(subject.previewCardFrame.width, subject.bounds.width)
    }

    // MARK: - dismissForTabTray

    func testDismissForTabTray_fadesOutPreview() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        subject.dismissForTabTray()

        XCTAssertEqual(subject.alpha, 0.0)
    }

    // MARK: - applyTheme

    func testApplyTheme_doesNotChangeLayout() {
        let subject = createSubject()
        subject.layoutIfNeeded()

        subject.applyTheme(theme: LightTheme())

        XCTAssertEqual(subject.previewCardFrame, subject.bounds)
    }

    // MARK: - Helpers

    private func createSubject(frame: CGRect? = nil,
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
