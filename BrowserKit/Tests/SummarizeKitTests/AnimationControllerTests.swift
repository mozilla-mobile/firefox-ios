// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import ComponentLibrary
@testable import SummarizeKit

@MainActor
final class AnimationControllerTests: XCTestCase {
    private var loadingStackView: UIView!
    private var parentViewController: UIViewController!
    private var snapshotContainer: UIView!
    private var snapshotView: UIView!
    private var summaryView: UIView!
    private var infoView: UIView!
    private var backgroundView: AIBackgroundEffectView!
    private var borderOverlayController: UIViewController!
    private let transform = CGAffineTransform(translationX: 0, y: 100)

    override func setUp() async throws {
        try await super.setUp()
        loadingStackView = UIView()
        parentViewController = UIViewController()
        snapshotContainer = UIView()
        snapshotView = UIView()
        summaryView = UIView()
        infoView = UIView()
        backgroundView = AIBackgroundEffectView(parentController: parentViewController)
        borderOverlayController = UIViewController()
    }

    override func tearDown() async throws {
        loadingStackView = nil
        parentViewController = nil
        snapshotContainer = nil
        snapshotView = nil
        summaryView = nil
        infoView = nil
        backgroundView = nil
        borderOverlayController = nil
        try await super.tearDown()
    }

    func test_animateViewDidAppear() {
        let controller = createSubject()

        controller.animateViewDidAppear(snapshotTransform: transform) {}

        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertEqual(loadingStackView.alpha, 1.0)
        XCTAssertNotEqual(snapshotView.layer.cornerRadius, 0.0)
    }

    func test_animateToSummary() {
        let controller = createSubject()
        let overlayParent = UIViewController()
        overlayParent.addChild(borderOverlayController)
        overlayParent.view.addSubview(borderOverlayController.view)
        borderOverlayController.didMove(toParent: overlayParent)
        var applyThemeCalled = false
        summaryView.alpha = 0.0

        controller.animateToSummary(
            snapshotTransform: transform,
            applyTheme: {
                applyThemeCalled = true
            }) {}

        XCTAssertEqual(summaryView.alpha, 1.0)
        XCTAssertEqual(loadingStackView.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertTrue(applyThemeCalled)
        XCTAssertNil(borderOverlayController.parent)
        XCTAssertNil(borderOverlayController.view.superview)
    }

    func test_animateToSummary_doesNotAnimateIfAlreadyVisible() {
        let controller = createSubject()
        var completionCalled = false
        summaryView.alpha = 1.0

        controller.animateToSummary(
            snapshotTransform: transform,
            applyTheme: {}
        ) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
    }

    func test_animateToInfo() {
        let controller = createSubject()

        controller.animateToInfo(snapshotTransform: transform) {}

        XCTAssertEqual(infoView.alpha, 1.0)
        XCTAssertEqual(summaryView.alpha, 0.0)
        XCTAssertEqual(loadingStackView.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
    }

    func test_animateToPanEnded() {
        let controller = createSubject()

        controller.animateToPanEnded(snapshotTransform: transform)

        XCTAssertEqual(summaryView.alpha, 1.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
    }

    func test_animateToDismiss() {
        let controller = createSubject()

        controller.animateToDismiss(snapshotTransform: transform) {}

        XCTAssertEqual(infoView.alpha, 0.0)
        XCTAssertEqual(loadingStackView.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertEqual(snapshotView.layer.cornerRadius, 0.0)
    }

    // MARK: - Test Helpers

    private func createSubject() -> DefaultAnimationController {
        return DefaultAnimationController(
            loadingStackView: loadingStackView,
            snapshotContainer: snapshotContainer,
            snapshotView: snapshotView,
            summaryView: summaryView,
            infoView: infoView,
            backgroundView: backgroundView,
            borderOverlayController: borderOverlayController
        )
    }
}
