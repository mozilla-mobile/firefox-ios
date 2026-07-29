// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatFullPageScreenshotViewTests: XCTestCase {
    private enum UX {
        static let presentationSize = CGSize(width: 390, height: 844)
        /// What the view is handed at the start of the presentation transition.
        static let transitionSize = CGSize(width: 1, height: 1)
        static let pageWidth: CGFloat = 320
        /// Short enough to fit the space the capture is given.
        static let shortPageHeight: CGFloat = 400
        static let tallPageHeight: CGFloat = 2400
    }

    // The geometry is checked against the previews. This covers the shapes that used to produce
    // inf/NaN and stop the view drawing: a page longer than the space it has, a page shorter than
    // it, no page at all, and the near-zero bounds of a presentation transition.
    func testLayout_acrossPageShapes_completes() {
        for image in [sampleImage(height: UX.tallPageHeight), sampleImage(height: UX.shortPageHeight), nil] {
            let subject = createSubject(image: image)
            subject.applyTheme(theme: LightTheme())

            layout(subject, in: UX.transitionSize)
            layout(subject, in: UX.presentationSize)

            XCTAssertEqual(subject.bounds.size, UX.presentationSize)
        }
    }

    // MARK: - Helpers

    private func createSubject(image: UIImage? = nil) -> WebCompatFullPageScreenshotView {
        return WebCompatFullPageScreenshotView(
            image: image,
            viewModel: WebCompatFullPageScreenshotViewModel(
                captureAccessibilityLabel: "Screenshot of the page",
                captureAccessibilityIdentifier: "capture"
            ),
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close")
        )
    }

    private func layout(_ subject: WebCompatFullPageScreenshotView, in size: CGSize) {
        subject.frame = CGRect(origin: .zero, size: size)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()
    }

    // Scale 1, or a long-page fixture allocates hundreds of megabytes at device scale.
    private func sampleImage(height: CGFloat) -> UIImage {
        let size = CGSize(width: UX.pageWidth, height: height)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
