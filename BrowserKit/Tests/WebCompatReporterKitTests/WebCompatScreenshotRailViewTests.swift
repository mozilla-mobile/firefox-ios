// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatScreenshotRailViewTests: XCTestCase {
    private enum UX {
        static let hostSize = CGSize(width: 390, height: 844)
        static let hostInset: CGFloat = 48
        static let tallPageRatio: CGFloat = 7.5
        /// Wider than it is tall, so the rail's natural height falls under its floor.
        static let widePageRatio: CGFloat = 0.46
        static let frameAccuracy: CGFloat = 0.5
    }

    private var host: UIView?

    override func tearDown() {
        host = nil
        super.tearDown()
    }

    func testRail_takesItsHeightFromThePageRatio() {
        let subject = createSubject(pageRatio: UX.tallPageRatio)

        XCTAssertEqual(
            subject.frame.height,
            WebCompatScreenshotRailView.UX.width * UX.tallPageRatio,
            accuracy: UX.frameAccuracy
        )
    }

    // A page wider than it is tall would otherwise leave the rail a sliver.
    func testRail_widePage_clampsToItsMinimumHeight() {
        let subject = createSubject(pageRatio: UX.widePageRatio)

        XCTAssertEqual(
            subject.frame.height,
            WebCompatScreenshotRailView.UX.minimumHeight,
            accuracy: UX.frameAccuracy
        )
    }

    // MARK: - Helpers

    /// Hosts and drives the rail the way the viewer does. Held for the test's lifetime, or it takes
    /// the rail's superview and every constraint against it down when it goes.
    private func createSubject(pageRatio: CGFloat) -> WebCompatScreenshotRailView {
        let subject = WebCompatScreenshotRailView(
            image: samplePage(ratio: pageRatio),
            pageHeightToWidthRatio: pageRatio
        )
        let host = UIView(frame: CGRect(origin: .zero, size: UX.hostSize))
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

        subject.applyTheme(theme: LightTheme())
        subject.update(scrollFraction: 0.5, visibleFraction: 0.4)
        host.setNeedsLayout()
        host.layoutIfNeeded()

        return subject
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
