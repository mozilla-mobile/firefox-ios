// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatFullPageScreenshotViewControllerTests: XCTestCase {
    func testCloseCallback_notifiesDelegate() throws {
        let delegate = MockWebCompatFullPageScreenshotDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        try screenshotView(of: subject).onClose?()

        XCTAssertEqual(delegate.didRequestDismissCallCount, 1)
    }

    // The report sheet underneath stays mounted, so without this VoiceOver swipes straight into it.
    func testLoadView_marksTheScreenshotViewAsModal() throws {
        let subject = createSubject()

        let screenshotView = try screenshotView(of: subject)

        XCTAssertTrue(screenshotView.accessibilityViewIsModal)
    }

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
        return WebCompatFullPageScreenshotViewController(
            image: nil,
            viewModel: WebCompatFullPageScreenshotViewModel(
                captureAccessibilityLabel: "Screenshot of the page",
                captureAccessibilityIdentifier: "capture"
            ),
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close"),
            theme: LightTheme()
        )
    }

    /// `loadView` assigns the screenshot view as the root view, so the tests reach it from there
    /// rather than through a property on the controller.
    private func screenshotView(
        of subject: WebCompatFullPageScreenshotViewController
    ) throws -> WebCompatFullPageScreenshotView {
        return try XCTUnwrap(subject.view as? WebCompatFullPageScreenshotView)
    }
}

private final class MockWebCompatFullPageScreenshotDelegate: WebCompatFullPageScreenshotDelegate {
    var didRequestDismissCallCount = 0

    func webCompatFullPageScreenshotDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }
}
