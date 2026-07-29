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
        static let veryTallPageHeight: CGFloat = 40000
        static let frameAccuracy: CGFloat = 0.5
        static let captureAccessibilityLabel = "Screenshot of the page"
        static let captureAccessibilityIdentifier = "capture"
    }

    func testCloseButton_invokesOnClose() {
        var closeCallCount = 0
        let subject = createSubject()
        subject.onClose = { closeCallCount += 1 }

        fireActions(subject.closeButton, for: .touchUpInside)

        XCTAssertEqual(closeCallCount, 1)
    }

    // MARK: - Accessibility

    // The capture is the whole point of the screen, and VoiceOver reached nothing but the close
    // button until it became an element in its own right.
    func testCapture_isAnAccessibilityElementDescribingThePage() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))

        XCTAssertTrue(subject.pageImageView.isAccessibilityElement)
        XCTAssertEqual(subject.pageImageView.accessibilityLabel, UX.captureAccessibilityLabel)
        XCTAssertEqual(subject.pageImageView.accessibilityIdentifier, UX.captureAccessibilityIdentifier)
        XCTAssertEqual(subject.pageImageView.accessibilityTraits, .image)
    }

    // MARK: - Content gating

    // Presentation starts near zero size, so everything hides until the size is real.
    func testLayout_atTransitionSize_hidesGeometryDrivenViews() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))

        layout(subject, in: UX.transitionSize)

        assertGeometryViewsHidden(subject, expected: true)
    }

    func testLayout_recoveringFromTransitionSize_showsGeometryDrivenViews() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.transitionSize)

        layout(subject, in: UX.presentationSize)

        assertGeometryViewsHidden(subject, expected: false)
    }

    func testLayout_withoutImage_hidesGeometryDrivenViews() {
        let subject = createSubject(image: nil)

        layout(subject, in: UX.presentationSize)

        assertGeometryViewsHidden(subject, expected: true)
    }

    // MARK: - Capture sizing

    // Stretching a short page to the full height would round the top corners over scrim and
    // leave the image's bottom edge square.
    func testLayout_shortPage_sizesTheCaptureToThePage() {
        let subject = createSubject(image: sampleImage(height: UX.shortPageHeight))

        layout(subject, in: UX.presentationSize)

        XCTAssertEqual(
            subject.scrollView.frame.height,
            subject.scrollView.contentSize.height,
            accuracy: UX.frameAccuracy
        )
    }

    // The rail used to back-solve its width from its capped height, which widened the capture
    // along with it. How long the page is can't change the capture's width.
    func testLayout_pageLength_doesNotChangeTheCaptureWidth() {
        let tallSubject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        let veryTallSubject = createSubject(image: sampleImage(height: UX.veryTallPageHeight))

        layout(tallSubject, in: UX.presentationSize)
        layout(veryTallSubject, in: UX.presentationSize)

        XCTAssertEqual(
            veryTallSubject.scrollView.frame.width,
            tallSubject.scrollView.frame.width,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Driving the rail

    // The rail is only ever as right as what it's told, and these two fractions are everything
    // the viewer tells it.
    func testScrollingToTheBottom_movesTheRailSpotlightToTheBottom() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scrollToBottom(subject)

        XCTAssertEqual(
            subject.railView.highlightView.frame.maxY,
            subject.railView.bounds.height,
            accuracy: UX.frameAccuracy
        )
    }

    func testLayout_sizesTheRailSpotlightToTheVisibleFractionOfThePage() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))

        layout(subject, in: UX.presentationSize)

        let visibleFraction = subject.scrollView.frame.height / subject.scrollView.contentSize.height
        XCTAssertEqual(
            subject.railView.highlightView.frame.height,
            subject.railView.bounds.height * visibleFraction,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Helpers

    private func createSubject(image: UIImage? = nil) -> WebCompatFullPageScreenshotView {
        return WebCompatFullPageScreenshotView(
            image: image,
            viewModel: WebCompatFullPageScreenshotViewModel(
                captureAccessibilityLabel: UX.captureAccessibilityLabel,
                captureAccessibilityIdentifier: UX.captureAccessibilityIdentifier
            ),
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close")
        )
    }

    private func layout(_ subject: WebCompatFullPageScreenshotView, in size: CGSize) {
        subject.frame = CGRect(origin: .zero, size: size)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()
    }

    private func scrollToBottom(_ subject: WebCompatFullPageScreenshotView) {
        let scrollView = subject.scrollView
        scrollView.contentOffset = CGPoint(
            x: 0,
            y: max(0, scrollView.contentSize.height - scrollView.bounds.height)
        )
        subject.setNeedsLayout()
        subject.layoutIfNeeded()
    }

    private func assertGeometryViewsHidden(
        _ subject: WebCompatFullPageScreenshotView,
        expected: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(subject.scrollView.isHidden, expected, "scrollView", file: file, line: line)
        XCTAssertEqual(subject.railView.isHidden, expected, "railView", file: file, line: line)
        XCTAssertFalse(subject.closeButton.isHidden, "The close button must stay reachable", file: file, line: line)
    }

    // Scale 1, or the 40000pt fixture allocates hundreds of megabytes at device scale.
    private func sampleImage(width: CGFloat = UX.pageWidth, height: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    // No UIApplication in logic tests, so `sendActions` does nothing.
    private func fireActions(_ control: UIControl, for event: UIControl.Event) {
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }
}
