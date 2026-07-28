// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebCompatReporterKit

/// `UIImage` isn't `Equatable`, so the view model hand-writes `==`. Nothing warns
/// you when a new property misses that operator, so pin the behaviour here.
@MainActor
final class WebCompatReportPreviewViewModelTests: XCTestCase {
    func testEquality_sameScreenshotInstance_isEqual() {
        let screenshot = sampleImage()

        XCTAssertEqual(makeViewModel(screenshot: screenshot), makeViewModel(screenshot: screenshot))
    }

    // Identity, not pixels. Two identical renders count as different, which means a
    // fresh capture always redraws. Wrong in the other direction would leave a stale
    // image on screen.
    func testEquality_distinctScreenshotInstances_areNotEqual() {
        XCTAssertNotEqual(makeViewModel(screenshot: sampleImage()), makeViewModel(screenshot: sampleImage()))
    }

    func testEquality_screenshotAppearing_isNotEqual() {
        XCTAssertNotEqual(makeViewModel(screenshot: nil), makeViewModel(screenshot: sampleImage()))
    }

    func testEquality_differingSections_areNotEqual() {
        let screenshot = sampleImage()
        let other = WebCompatReportPreviewViewModel.PreviewSection(
            id: "system",
            title: "system",
            a11yIdentifier: "section.system",
            contentA11yIdentifier: "section.system.content",
            rows: [WebCompatReportPreviewViewModel.PreviewRow(id: "memory", label: "memory", value: .quantity(6144))]
        )

        XCTAssertNotEqual(
            makeViewModel(screenshot: screenshot),
            makeViewModel(screenshot: screenshot, sections: [other])
        )
    }

    // MARK: - Helpers

    private func makeViewModel(
        screenshot: UIImage?,
        sections: [WebCompatReportPreviewViewModel.PreviewSection] = []
    ) -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "close",
            screenshotAccessibilityLabel: "Screenshot",
            screenshotA11yIdentifier: "screenshot",
            screenshot: screenshot,
            sections: sections
        )
    }

    private func sampleImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}
