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
        /// What the view is handed at the start of the presentation transition.
        static let transitionSize = CGSize(width: 1, height: 1)
        static let pageWidth: CGFloat = 320
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

        fireActions(firstSubview(ofType: CloseButton.self, in: subject.view), for: .touchUpInside)

        XCTAssertEqual(delegate.didTapCloseCallCount, 1)
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
        XCTAssertEqual(view.thumbnailContainer.isHidden, expected, "thumbnailContainer", file: file, line: line)
        XCTAssertEqual(view.highlightView.isHidden, expected, "highlightView", file: file, line: line)
    }

    private func sampleImage(width: CGFloat = UX.pageWidth, height: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    // No UIApplication in logic tests, so `sendActions` does nothing.
    private func fireActions(_ control: UIControl?, for event: UIControl.Event) {
        guard let control else { return }
        for target in control.allTargets {
            let object = target as NSObject
            control.actions(forTarget: target, forControlEvent: event)?.forEach {
                object.perform(Selector($0))
            }
        }
    }

    private func firstSubview<T: UIView>(ofType type: T.Type, in view: UIView?) -> T? {
        guard let view else { return nil }
        for subview in view.subviews {
            if let match = subview as? T { return match }
            if let match = firstSubview(ofType: type, in: subview) { return match }
        }
        return nil
    }
}

private final class MockWebCompatFullPageScreenshotDelegate: WebCompatFullPageScreenshotDelegate {
    var didTapCloseCallCount = 0

    func webCompatFullPageScreenshotDidTapClose() {
        didTapCloseCallCount += 1
    }
}
