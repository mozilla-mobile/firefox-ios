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

    func testCloseButton_invokesOnClose() {
        var closeCallCount = 0
        let subject = createSubject()
        subject.onClose = { closeCallCount += 1 }

        fireActions(subject.closeButton, for: .touchUpInside)

        XCTAssertEqual(closeCallCount, 1)
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

        XCTAssertEqual(
            subject.highlightView.frame.minY,
            subject.thumbnailContainer.frame.minY,
            accuracy: UX.frameAccuracy
        )
    }

    func testHighlight_scrolledToBottom_sitsAtBottomOfThumbnail() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scroll(subject, toFractionOfMaximumOffset: 1)

        XCTAssertEqual(
            subject.highlightView.frame.maxY,
            subject.thumbnailContainer.frame.maxY,
            accuracy: UX.frameAccuracy
        )
    }

    // Rubber-banding pushes the offset past both ends. The highlight has to stay put.
    func testHighlight_whenOverScrolled_staysWithinThumbnail() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scroll(subject, toFractionOfMaximumOffset: 1.4)
        XCTAssertLessThanOrEqual(
            subject.highlightView.frame.maxY,
            subject.thumbnailContainer.frame.maxY + UX.frameAccuracy
        )

        scroll(subject, toFractionOfMaximumOffset: -0.4)
        XCTAssertGreaterThanOrEqual(
            subject.highlightView.frame.minY,
            subject.thumbnailContainer.frame.minY - UX.frameAccuracy
        )
    }

    func testHighlight_onVeryTallPage_keepsAGrabbableMinimumHeight() {
        let subject = createSubject(image: sampleImage(height: UX.veryTallPageHeight))

        layout(subject, in: UX.presentationSize)

        XCTAssertGreaterThanOrEqual(subject.highlightView.frame.height, UX.minimumHighlightHeight)
    }

    // The rail used to back-solve its width from the capped height, so a tall enough page
    // collapsed it to a sliver and widened the capture along with it.
    func testLayout_onVeryTallPage_keepsRailWidthAndCaptureWidth() {
        let tallSubject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        let veryTallSubject = createSubject(image: sampleImage(height: UX.veryTallPageHeight))

        layout(tallSubject, in: UX.presentationSize)
        layout(veryTallSubject, in: UX.presentationSize)

        XCTAssertEqual(veryTallSubject.thumbnailContainer.frame.width, UX.railWidth, accuracy: UX.frameAccuracy)
        XCTAssertEqual(
            veryTallSubject.scrollView.frame.width,
            tallSubject.scrollView.frame.width,
            accuracy: UX.frameAccuracy,
            "Page length must not change the capture width"
        )
    }

    // The rail shows the whole page at rail width, so its height follows the page ratio while
    // that fits. The dimmed page filling it used to win against this and stretch the rail down
    // the screen, which made the highlight far bigger than the fraction of the page on show.
    func testLayout_tallPage_sizesTheRailToThePageRatio() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))

        layout(subject, in: UX.presentationSize)

        let pageRatio = UX.tallPageHeight / UX.pageWidth
        XCTAssertEqual(
            subject.thumbnailContainer.frame.height,
            UX.railWidth * pageRatio,
            accuracy: UX.frameAccuracy
        )
    }

    // The same stretch left a short page's rail taller than the capture beside it.
    func testLayout_shortPage_keepsTheRailNoTallerThanTheCapture() {
        let subject = createSubject(image: sampleImage(height: UX.shortPageHeight))

        layout(subject, in: UX.presentationSize)

        XCTAssertLessThanOrEqual(
            subject.thumbnailContainer.frame.maxY,
            subject.scrollView.frame.maxY + UX.frameAccuracy
        )
    }

    // A page wider than it is tall makes the rail short. The highlight's minimum height used
    // to exceed it, so it overhung the rail and stopped tracking the scroll entirely.
    func testHighlight_onWideLandscapePage_staysInsideTheRailAndTracksScroll() {
        let subject = createSubject(
            image: sampleImage(width: UX.landscapeSize.width, height: UX.landscapeSize.height)
        )
        layout(subject, in: UX.landscapeSize)
        let topOffset = subject.highlightView.frame.minY

        scroll(subject, toFractionOfMaximumOffset: 1)

        XCTAssertLessThanOrEqual(
            subject.highlightView.frame.maxY,
            subject.thumbnailContainer.frame.maxY + UX.frameAccuracy,
            "The highlight must not overhang the rail"
        )
        XCTAssertGreaterThan(subject.highlightView.frame.minY, topOffset, "The highlight must track the scroll")
    }

    // A drifting bright slice spotlights a different part of the page than the capture shows.
    func testHighlight_brightSliceTracksTheHighlightOffset() {
        let subject = createSubject(image: sampleImage(height: UX.tallPageHeight))
        layout(subject, in: UX.presentationSize)

        scroll(subject, toFractionOfMaximumOffset: 0.5)

        let offsetFromThumbnailTop = subject.highlightView.frame.minY - subject.thumbnailContainer.frame.minY
        XCTAssertGreaterThan(offsetFromThumbnailTop, 0, "Expected the highlight to have moved down the rail")
        XCTAssertEqual(
            subject.brightWindowImageView.frame.minY,
            -offsetFromThumbnailTop,
            accuracy: UX.frameAccuracy
        )
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

    // MARK: - Helpers

    private func createSubject(image: UIImage? = nil) -> WebCompatFullPageScreenshotView {
        return WebCompatFullPageScreenshotView(
            image: image,
            closeButtonViewModel: CloseButtonViewModel(a11yLabel: "Close", a11yIdentifier: "close")
        )
    }

    private func layout(_ subject: WebCompatFullPageScreenshotView, in size: CGSize) {
        subject.frame = CGRect(origin: .zero, size: size)
        subject.layoutIfNeeded()
    }

    private func scroll(_ subject: WebCompatFullPageScreenshotView, toFractionOfMaximumOffset fraction: CGFloat) {
        let scrollView = subject.scrollView
        let maximumOffset = max(1, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.contentOffset = CGPoint(x: 0, y: maximumOffset * fraction)
        subject.layoutIfNeeded()
    }

    private func assertGeometryViewsHidden(
        _ subject: WebCompatFullPageScreenshotView,
        expected: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(subject.scrollView.isHidden, expected, "scrollView", file: file, line: line)
        XCTAssertEqual(
            subject.brightWindowContainer.isHidden,
            expected,
            "brightWindowContainer",
            file: file,
            line: line
        )
        XCTAssertEqual(subject.thumbnailContainer.isHidden, expected, "thumbnailContainer", file: file, line: line)
        XCTAssertEqual(subject.highlightView.isHidden, expected, "highlightView", file: file, line: line)
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
