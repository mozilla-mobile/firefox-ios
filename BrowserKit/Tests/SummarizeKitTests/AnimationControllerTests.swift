// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SummarizeKit

@MainActor
final class AnimationControllerTests: XCTestCase {
    private var view: UIView!
    private var loadingLabel: UILabel!
    private var snapshotContainer: UIView!
    private var snapshotView: UIView!
    private var summaryView: UIView!
    private var infoView: UIView!
    private var backgroundGradient: CAGradientLayer!
    private var borderOverlayController: UIViewController!
    private let transform = CGAffineTransform(translationX: 0, y: 100)

    override func setUp() async throws {
        try await super.setUp()
        view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        loadingLabel = UILabel()
        snapshotContainer = UIView()
        snapshotView = UIView()
        summaryView = UIView()
        infoView = UIView()
        backgroundGradient = CAGradientLayer()
        borderOverlayController = UIViewController()
    }

    override func tearDown() async throws {
        view = nil
        loadingLabel = nil
        snapshotContainer = nil
        snapshotView = nil
        summaryView = nil
        infoView = nil
        backgroundGradient = nil
        borderOverlayController = nil
        try await super.tearDown()
    }

    func test_animateViewDidAppear() {
        let controller = createSubject()

        controller.animateViewDidAppear(snapshotTransform: transform) {}

        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertEqual(loadingLabel.alpha, 1.0)
        XCTAssertNotEqual(snapshotView.layer.cornerRadius, 0.0)
    }

    func test_animateToSummary() {
        let controller = createSubject()
        let parentViewController = UIViewController()
        parentViewController.addChild(borderOverlayController)
        parentViewController.view.addSubview(borderOverlayController.view)
        borderOverlayController.didMove(toParent: parentViewController)
        var applyThemeCalled = false
        view.layer.addSublayer(backgroundGradient)
        summaryView.alpha = 0.0

        controller.animateToSummary(
            snapshotTransform: transform,
            applyTheme: {
                applyThemeCalled = true
            }) {}

        XCTAssertEqual(summaryView.alpha, 1.0)
        XCTAssertEqual(loadingLabel.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertTrue(applyThemeCalled)
        XCTAssertNil(borderOverlayController.parent)
        XCTAssertNil(borderOverlayController.view.superview)
        XCTAssertNil(backgroundGradient.superlayer)
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
        XCTAssertEqual(loadingLabel.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertEqual(backgroundGradient.superlayer, view.layer)
    }

    func test_animateToInfo_doesNotInsertBackgroundGradientIfAlreadyPresent() {
        let controller = createSubject()
        view.layer.addSublayer(backgroundGradient)

        controller.animateToInfo(snapshotTransform: transform) {}

        XCTAssertEqual(view.layer.sublayers?.count ?? 0, 1, "There should be only one sublayer")
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
        XCTAssertEqual(loadingLabel.alpha, 0.0)
        XCTAssertEqual(snapshotContainer.transform, transform)
        XCTAssertEqual(snapshotView.layer.cornerRadius, 0.0)
    }

    // MARK: - Test Helpers

    private func createSubject() -> DefaultAnimationController {
        return DefaultAnimationController(
            view: view,
            loadingLabel: loadingLabel,
            snapshotContainer: snapshotContainer,
            snapshotView: snapshotView,
            summaryView: summaryView,
            infoView: infoView,
            backgroundGradient: backgroundGradient,
            borderOverlayController: borderOverlayController
        )
    }
}
