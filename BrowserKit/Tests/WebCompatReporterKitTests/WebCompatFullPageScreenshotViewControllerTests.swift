// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import TestKit
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatFullPageScreenshotViewControllerTests: XCTestCase {
    // The two-finger scrub is the expected way out of a modal.
    func testAccessibilityEscape_notifiesDelegate() {
        let delegate = MockWebCompatFullPageScreenshotDelegate()
        let subject = createSubject()
        subject.delegate = delegate

        XCTAssertTrue(subject.accessibilityPerformEscape())
        XCTAssertEqual(delegate.didRequestDismissCallCount, 1)
    }

    // Reporting the gesture as handled with nobody listening would swallow it silently.
    func testAccessibilityEscape_withoutDelegate_isNotHandled() {
        XCTAssertFalse(createSubject().accessibilityPerformEscape())
    }

    // MARK: - Helpers

    private func createSubject() -> WebCompatFullPageScreenshotViewController {
        let subject = WebCompatFullPageScreenshotViewController(
            image: nil,
            viewModel: WebCompatFullPageScreenshotViewModel(
                captureAccessibilityLabel: "Screenshot of the page",
                captureAccessibilityIdentifier: "capture"
            ),
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close"),
            windowUUID: .XCTestDefaultUUID,
            themeManager: DefaultThemeManager(sharedContainerIdentifier: ""),
            notificationCenter: NotificationCenter.default
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockWebCompatFullPageScreenshotDelegate: WebCompatFullPageScreenshotDelegate {
    var didRequestDismissCallCount = 0

    func webCompatFullPageScreenshotDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }
}
