// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

@MainActor
final class GradientProgressBarTests: XCTestCase {
    private var subject: GradientProgressBar!

    override func setUp() async throws {
        try await super.setUp()
        subject = GradientProgressBar(frame: CGRect(x: 0, y: 0, width: 320, height: 3))
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    func test_setProgress_ltr_maskGrowsFromLeadingEdge() {
        subject.semanticContentAttribute = .forceLeftToRight
        subject.setProgress(0.5, animated: false)

        XCTAssertEqual(subject.alphaMaskLayer.frame.origin.x, 0)
        XCTAssertEqual(subject.alphaMaskLayer.frame.width, 160)
    }

    func test_setProgress_rtl_maskGrowsFromTrailingEdge() {
        subject.semanticContentAttribute = .forceRightToLeft
        subject.setProgress(0.5, animated: false)

        XCTAssertEqual(subject.alphaMaskLayer.frame.width, 160)
        XCTAssertEqual(subject.alphaMaskLayer.frame.maxX, subject.bounds.width)
    }

    func test_directionChange_midLoad_recalculatesFromNewEdge() {
        subject.semanticContentAttribute = .forceLeftToRight
        subject.setProgress(0.3, animated: false)
        XCTAssertEqual(subject.alphaMaskLayer.frame.origin.x, 0)

        subject.semanticContentAttribute = .forceRightToLeft
        subject.setProgress(0.6, animated: false)

        XCTAssertEqual(subject.alphaMaskLayer.frame.maxX, subject.bounds.width)
    }

    func test_hideProgressBar_ltr_exitsTowardTrailingEdge() {
        subject.semanticContentAttribute = .forceLeftToRight
        subject.setProgress(1, animated: false)
        subject.hideProgressBar()

        let toValue = (subject.gradientLayer.animation(forKey: "position") as? CABasicAnimation)?.toValue as? CGPoint
        XCTAssertEqual(toValue?.x, subject.gradientLayer.frame.width)
    }

    func test_hideProgressBar_rtl_exitsTowardLeadingEdge() {
        subject.semanticContentAttribute = .forceRightToLeft
        subject.setProgress(1, animated: false)
        subject.hideProgressBar()

        let toValue = (subject.gradientLayer.animation(forKey: "position") as? CABasicAnimation)?.toValue as? CGPoint
        XCTAssertEqual(toValue?.x, -subject.gradientLayer.frame.width)
    }
}
