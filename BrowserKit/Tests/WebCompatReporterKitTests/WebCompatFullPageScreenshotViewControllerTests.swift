// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatFullPageScreenshotViewControllerTests: XCTestCase {
    private enum UX {
        static let presentationSize = CGSize(width: 390, height: 844)
        static let landscapeSize = CGSize(width: 852, height: 393)
        /// What the view is handed at the start of the presentation transition.
        static let transitionSize = CGSize(width: 1, height: 1)
        static let pageWidth: CGFloat = 320
        /// Short enough to fit the space the capture is given.
        static let shortPageHeight: CGFloat = 400
        static let tallPageHeight: CGFloat = 2400
        static let veryTallPageHeight: CGFloat = 40000
        /// Mirrors `WebCompatFullPageScreenshotView.UX.minimumHighlightHeight`, which is private.
        static let minimumHighlightHeight: CGFloat = 24
        /// Mirrors `WebCompatFullPageScreenshotView.UX.thumbnailWidth`, which is private.
        static let railWidth: CGFloat = 44
        static let frameAccuracy: CGFloat = 0.5
    }

    func testCloseButton_notifiesDelegate() {
        let delegate = MockWebCompatFullPageScreenshotDelegate()
        let subject = createSubject()
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        fireActions(subject.screenshotView.closeButton, for: .touchUpInside)

        XCTAssertEqual(delegate.didRequestDismissCallCount, 1)
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

    // MARK: - Viewport highlight

    func testHighlight_atTopOfPage_sitsAtTopOfThumbnail() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        let view = subject.screenshotView
        XCTAssertEqual(view.highlightView.frame.minY, view.thumbnailContainer.frame.minY, accuracy: UX.frameAccuracy)
    }

    func testHighlight_scrolledToBottom_sitsAtBottomOfThumbnail() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scroll(subject, toFractionOfMaximumOffset: 1)

        let view = subject.screenshotView
        XCTAssertEqual(view.highlightView.frame.maxY, view.thumbnailContainer.frame.maxY, accuracy: UX.frameAccuracy)
    }

    // Rubber-banding pushes the offset past both ends. The highlight has to stay put.
    func testHighlight_whenOverScrolled_staysWithinThumbnail() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)
        let view = subject.screenshotView

        scroll(subject, toFractionOfMaximumOffset: 1.4)
        XCTAssertLessThanOrEqual(view.highlightView.frame.maxY, view.thumbnailContainer.frame.maxY + UX.frameAccuracy)

        scroll(subject, toFractionOfMaximumOffset: -0.4)
        XCTAssertGreaterThanOrEqual(view.highlightView.frame.minY, view.thumbnailContainer.frame.minY - UX.frameAccuracy)
    }

    func testHighlight_onVeryTallPage_keepsAGrabbableMinimumHeight() {
        let subject = createSubject(image: sampleImage(height: UX.veryTallPageHeight))
        layout(subject, in: UX.presentationSize)

        XCTAssertGreaterThanOrEqual(subject.screenshotView.highlightView.frame.height, UX.minimumHighlightHeight)
    }

    // The rail used to back-solve its width from the capped height, so a tall enough page
    // collapsed it to a sliver and widened the capture along with it.
    func testLayout_onVeryTallPage_keepsRailWidthAndCaptureWidth() {
        let tallSubject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        let veryTallSubject = createSubject(image: sampleImage(height: UX.veryTallPageHeight))

        layout(tallSubject, in: UX.presentationSize)
        layout(veryTallSubject, in: UX.presentationSize)

        let veryTallView = veryTallSubject.screenshotView
        XCTAssertEqual(veryTallView.thumbnailContainer.frame.width, UX.railWidth, accuracy: UX.frameAccuracy)
        XCTAssertEqual(
            veryTallView.scrollView.frame.width,
            tallSubject.screenshotView.scrollView.frame.width,
            accuracy: UX.frameAccuracy,
            "Page length must not change the capture width"
        )
    }

    // A page wider than it is tall makes the rail short. The highlight's minimum height used
    // to exceed it, so it overhung the rail and stopped tracking the scroll entirely.
    func testHighlight_onWideLandscapePage_staysInsideTheRailAndTracksScroll() {
        let subject = createSubject(
            image: sampleImage(width: UX.landscapeSize.width, height: UX.landscapeSize.height)
        )
        layout(subject, in: UX.landscapeSize)
        let view = subject.screenshotView
        let topOffset = view.highlightView.frame.minY

        scroll(subject, toFractionOfMaximumOffset: 1)

        XCTAssertLessThanOrEqual(
            view.highlightView.frame.maxY,
            view.thumbnailContainer.frame.maxY + UX.frameAccuracy,
            "The highlight must not overhang the rail"
        )
        XCTAssertGreaterThan(view.highlightView.frame.minY, topOffset, "The highlight must track the scroll")
    }

    // MARK: - Capture sizing

    // Stretching a short page to the full height would round the top corners over scrim and
    // leave the image's bottom edge square.
    func testLayout_shortPage_sizesTheCaptureToThePage() {
        let subject = createSubject(image: sampleImage(height: UX.shortPageHeight))

        layout(subject, in: UX.presentationSize)

        let scrollView = subject.screenshotView.scrollView
        XCTAssertEqual(scrollView.frame.height, scrollView.contentSize.height, accuracy: UX.frameAccuracy)
    }

    // A drifting bright slice spotlights a different part of the page than the capture shows.
    func testHighlight_brightSliceTracksTheHighlightOffset() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scroll(subject, toFractionOfMaximumOffset: 0.5)

        let view = subject.screenshotView
        let offsetFromThumbnailTop = view.highlightView.frame.minY - view.thumbnailContainer.frame.minY
        XCTAssertGreaterThan(offsetFromThumbnailTop, 0, "Expected the highlight to have moved down the rail")
        XCTAssertEqual(view.brightWindowImageView.frame.minY, -offsetFromThumbnailTop, accuracy: UX.frameAccuracy)
    }

    // MARK: - Helpers

    private func createSubject(image: UIImage? = nil) -> WebCompatFullPageScreenshotViewController {
        return WebCompatFullPageScreenshotViewController(
            image: image,
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close"),
            theme: LightTheme()
        )
    }

    private func layout(_ subject: WebCompatFullPageScreenshotViewController, in size: CGSize) {
        subject.loadViewIfNeeded()
        subject.view.frame = CGRect(origin: .zero, size: size)
        subject.view.layoutIfNeeded()
    }

    private func scroll(
        _ subject: WebCompatFullPageScreenshotViewController,
        toFractionOfMaximumOffset fraction: CGFloat
    ) {
        let scrollView = subject.screenshotView.scrollView
        let maximumOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.contentOffset = CGPoint(x: 0, y: maximumOffset * fraction)
    }

    private func assertGeometryViewsHidden(
        _ subject: WebCompatFullPageScreenshotViewController,
        expected: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = subject.screenshotView
        XCTAssertEqual(view.scrollView.isHidden, expected, "scrollView", file: file, line: line)
        XCTAssertEqual(view.brightWindowContainer.isHidden, expected, "brightWindowContainer", file: file, line: line)
        XCTAssertEqual(view.thumbnailContainer.isHidden, expected, "thumbnailContainer", file: file, line: line)
        XCTAssertEqual(view.highlightView.isHidden, expected, "highlightView", file: file, line: line)
        XCTAssertFalse(view.closeButton.isHidden, "The close button must stay reachable", file: file, line: line)
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

private final class MockWebCompatFullPageScreenshotDelegate: WebCompatFullPageScreenshotDelegate {
    var didRequestDismissCallCount = 0

    func webCompatFullPageScreenshotDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }
}
