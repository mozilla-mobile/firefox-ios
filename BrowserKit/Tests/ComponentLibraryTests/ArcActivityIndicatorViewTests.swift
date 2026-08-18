// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
@testable import ComponentLibrary

@MainActor
final class ArcActivityIndicatorViewTests: XCTestCase {
    private var view: ArcActivityIndicatorView!

    override func setUp() async throws {
        try await super.setUp()
        view = ArcActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
    }

    override func tearDown() async throws {
        view = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests
    func testInit_disablesUserInteraction() {
        XCTAssertFalse(view.isUserInteractionEnabled)
    }

    func testInit_setsClearBackground() {
        XCTAssertEqual(view.backgroundColor, .clear)
    }

    func testInit_addsTrackAndArcSublayers() {
        XCTAssertEqual(view.layer.sublayers?.count, 2)
    }

    // MARK: - startAnimating Tests
    func testStartAnimating_unhidesView() {
        view.isHidden = true

        view.startAnimating()

        XCTAssertFalse(view.isHidden)
    }

    func testStartAnimating_firstCall_returnsTrue() {
        let didChange = view.startAnimating()

        XCTAssertTrue(didChange)
    }

    func testStartAnimating_calledAgainWhileAnimating_returnsFalse() {
        view.startAnimating()
        let didChangeSecondTime = view.startAnimating()

        XCTAssertFalse(didChangeSecondTime)
    }

    func testStartAnimating_addsRotationAnimationToLayer() {
        view.startAnimating()

        XCTAssertNotNil(view.layer.animation(forKey: "rotation"))
    }

    // MARK: - stopAnimating Tests
    func testStopAnimating_hidesView() {
        view.startAnimating()

        view.stopAnimating()

        XCTAssertTrue(view.isHidden)
    }

    func testStopAnimating_afterAnimating_returnsTrue() {
        view.startAnimating()
        let didChange = view.stopAnimating()

        XCTAssertTrue(didChange)
    }

    func testStopAnimating_whenNotAnimating_returnsFalse() {
        let didChange = view.stopAnimating()

        XCTAssertFalse(didChange)
    }

    func testStopAnimating_removesRotationAnimationFromLayer() {
        view.startAnimating()

        view.stopAnimating()

        XCTAssertNil(view.layer.animation(forKey: "rotation"))
    }

    // MARK: - Layout Tests
    func testLayoutSubviews_computesPathsForBothLayers() {
        view.layoutIfNeeded()

        let sublayers = view.layer.sublayers as? [CAShapeLayer]
        XCTAssertNotNil(sublayers?.first?.path)
        XCTAssertNotNil(sublayers?.last?.path)
    }

    func testLayoutSubviews_withZeroFrame_doesNotCrash() {
        let zeroFrameView = ArcActivityIndicatorView(frame: .zero)

        zeroFrameView.layoutIfNeeded()

        XCTAssertNotNil(zeroFrameView)
    }

    // MARK: - Theme Tests
    func testApplyTheme_setsTrackLayerStrokeColor() {
        let theme = LightTheme()

        view.applyTheme(theme: theme)

        let sublayers = view.layer.sublayers as? [CAShapeLayer]
        XCTAssertEqual(sublayers?.first?.strokeColor, theme.colors.borderSecondary.cgColor)
    }

    func testApplyTheme_setsArcLayerStrokeColor() {
        let theme = LightTheme()

        view.applyTheme(theme: theme)

        let sublayers = view.layer.sublayers as? [CAShapeLayer]
        XCTAssertEqual(sublayers?.last?.strokeColor, theme.colors.actionPrimary.cgColor)
    }
}
