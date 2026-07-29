// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatScreenshotRailViewTests: XCTestCase {
    private enum UX {
        static let hostHeight: CGFloat = 844
        /// Leaves the rail 748pt to grow into, matching the viewer's insets on a 844pt screen.
        static let hostInset: CGFloat = 48
        static let availableHeight: CGFloat = 748
        static let tallPageRatio: CGFloat = 7.5
        static let longPageRatio: CGFloat = 125
        /// Wider than it is tall, so the rail's natural height falls under its floor.
        static let widePageRatio: CGFloat = 0.46
        static let frameAccuracy: CGFloat = 0.5
    }

    private var host: UIView?

    override func tearDown() {
        host = nil
        super.tearDown()
    }

    // MARK: - Rail sizing

    func testRail_tallPage_takesItsHeightFromThePageRatio() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        XCTAssertEqual(
            subject.frame.height,
            WebCompatScreenshotRailView.UX.width * UX.tallPageRatio,
            accuracy: UX.frameAccuracy
        )
    }

    // A page wider than it is tall would otherwise leave the rail a sliver, and a sliver gives the
    // highlight no room to travel: it freezes and overhangs.
    func testRail_widePage_clampsToItsMinimumHeight() {
        let subject = createSubject(pageRatio: UX.widePageRatio)

        XCTAssertEqual(
            subject.frame.height,
            WebCompatScreenshotRailView.UX.minimumHeight,
            accuracy: UX.frameAccuracy
        )
    }

    // The rail squashes a long page rather than narrowing. Narrowing used to feed back into the
    // caller's margins and reflow everything beside it.
    func testRail_longPage_squashesToTheAvailableHeightAndKeepsItsWidth() {
        let subject = createSubject(pageRatio: UX.longPageRatio)

        XCTAssertEqual(subject.frame.height, UX.availableHeight, accuracy: UX.frameAccuracy)
        XCTAssertEqual(
            subject.frame.width,
            WebCompatScreenshotRailView.UX.width,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Highlight size

    // The window says how much of the page is on show, so it has to be that fraction of the rail.
    func testHighlight_isTheVisibleFractionOfTheRail() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 0, visibleFraction: 0.4)
        layout()

        XCTAssertEqual(
            subject.highlightView.frame.height,
            subject.frame.height * 0.4,
            accuracy: UX.frameAccuracy
        )
    }

    func testHighlight_whenTheWholePageIsVisible_coversTheWholeRail() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 0, visibleFraction: 1)
        layout()

        XCTAssertEqual(
            subject.highlightView.frame.height,
            subject.frame.height,
            accuracy: UX.frameAccuracy
        )
    }

    // Exact, not a lower bound: `>=` also passes when the window fills the entire rail.
    func testHighlight_onALongPage_clampsToItsMinimumHeight() {
        let subject = createSubject(pageRatio: UX.longPageRatio)

        subject.update(scrollFraction: 0, visibleFraction: 0.01)
        layout()

        XCTAssertEqual(
            subject.highlightView.frame.height,
            WebCompatScreenshotRailView.UX.minimumHighlightHeight,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Highlight travel

    func testHighlight_atTheStartOfThePage_sitsAtTheTopOfTheRail() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 0, visibleFraction: 0.4)
        layout()

        XCTAssertEqual(subject.highlightView.frame.minY, 0, accuracy: UX.frameAccuracy)
    }

    func testHighlight_atTheEndOfThePage_sitsAtTheBottomOfTheRail() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 1, visibleFraction: 0.4)
        layout()

        XCTAssertEqual(
            subject.highlightView.frame.maxY,
            subject.bounds.height,
            accuracy: UX.frameAccuracy
        )
    }

    // Rubber-banding pushes the caller's fraction past both ends. The window has to stay put.
    func testHighlight_whenTheFractionOvershoots_staysWithinTheRail() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 1.4, visibleFraction: 0.4)
        layout()
        XCTAssertEqual(
            subject.highlightView.frame.maxY,
            subject.bounds.height,
            accuracy: UX.frameAccuracy
        )

        subject.update(scrollFraction: -0.4, visibleFraction: 0.4)
        layout()
        XCTAssertEqual(subject.highlightView.frame.minY, 0, accuracy: UX.frameAccuracy)
    }

    // The offset is a transform precisely so it lands without waiting for another layout pass.
    func testHighlight_moves_withoutAnotherLayoutPass() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)
        subject.update(scrollFraction: 0, visibleFraction: 0.4)
        layout()

        subject.update(scrollFraction: 1, visibleFraction: 0.4)

        XCTAssertEqual(
            subject.highlightView.frame.maxY,
            subject.bounds.height,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Spotlight

    // A drifting bright copy spotlights a different part of the page than the caller is showing.
    func testSpotlight_staysRegisteredWithTheDimmedPage() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.update(scrollFraction: 0.5, visibleFraction: 0.4)
        layout()

        XCTAssertGreaterThan(
            subject.highlightView.frame.minY,
            0,
            "Expected the highlight to have moved down the rail"
        )
        XCTAssertEqual(
            subject.spotlightContainer.convert(subject.spotlightPageView.frame, to: subject).minY,
            0,
            accuracy: UX.frameAccuracy,
            "The bright copy must stay registered with the dimmed page"
        )
        XCTAssertEqual(
            subject.spotlightPageView.frame.height,
            subject.frame.height,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Accessibility

    // The rail maps content it doesn't own, so VoiceOver reads that content once, at the source.
    func testRail_isHiddenFromVoiceOver() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        XCTAssertFalse(subject.isAccessibilityElement)
        XCTAssertFalse(subject.clipView.isAccessibilityElement)
        XCTAssertFalse(subject.dimmedPageView.isAccessibilityElement)
        XCTAssertFalse(subject.spotlightContainer.isAccessibilityElement)
        XCTAssertFalse(subject.spotlightPageView.isAccessibilityElement)
        XCTAssertFalse(subject.highlightView.isAccessibilityElement)
    }

    // MARK: - Theming

    // Both strokes sit over the page the rail maps, which doesn't follow the app theme. An
    // inverting token put a white ring on a white page in the light themes.
    func testApplyTheme_strokesDoNotInvertBetweenPalettes() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        subject.applyTheme(theme: LightTheme())
        let lightRing = subject.highlightView.layer.borderColor
        let lightBorder = subject.clipView.layer.borderColor

        subject.applyTheme(theme: DarkTheme())

        XCTAssertEqual(subject.highlightView.layer.borderColor, lightRing)
        XCTAssertEqual(subject.clipView.layer.borderColor, lightBorder)
    }

    // MARK: - Helpers

    /// Hosts the rail the way the viewer does: pinned to the top, free to grow to `availableHeight`
    /// and no further. Held for the test's lifetime, or it takes the rail's superview and every
    /// constraint against it down when it goes.
    private func createSubject(pageRatio: CGFloat) -> WebCompatScreenshotRailView {
        let subject = WebCompatScreenshotRailView(
            image: samplePage(ratio: pageRatio),
            pageHeightToWidthRatio: pageRatio
        )
        let host = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: UX.hostHeight))
        host.addSubview(subject)
        self.host = host

        let bottom = subject.bottomAnchor.constraint(
            lessThanOrEqualTo: host.bottomAnchor,
            constant: -UX.hostInset
        )
        bottom.priority = .required - 1
        NSLayoutConstraint.activate([
            subject.topAnchor.constraint(equalTo: host.topAnchor, constant: UX.hostInset),
            subject.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            bottom
        ])
        layout()

        return subject
    }

    /// The rail's placement constraints belong to the host, so the host is the one that lays out.
    /// It also has to be flagged: `layoutIfNeeded()` only descends when the receiver itself is dirty,
    /// and a constraint constant change flags the rail rather than its ancestors.
    private func layout() {
        host?.setNeedsLayout()
        host?.layoutIfNeeded()
    }

    // Scale 1, or a long-page fixture allocates hundreds of megabytes at device scale.
    private func samplePage(ratio: CGFloat) -> UIImage {
        let size = CGSize(width: 320, height: 320 * ratio)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
