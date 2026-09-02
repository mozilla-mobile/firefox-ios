// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import ComponentLibrary

@MainActor
final class GradientViewTests: XCTestCase {
    func test_layerClass_isGradientLayer() {
        let subject = GradientView()

        XCTAssertTrue(subject.layer is CAGradientLayer)
    }

    func test_configure_setsColorsAndGeometry() throws {
        let subject = GradientView()
        let gradient = Gradient(colors: [.red, .blue])

        subject.configure(gradient: gradient,
                          startPoint: CGPoint(x: 0, y: 0.5),
                          endPoint: CGPoint(x: 1, y: 0.5),
                          locations: [0, 1])

        let layer = try XCTUnwrap(subject.layer as? CAGradientLayer)
        XCTAssertEqual(layer.colors as? [CGColor], gradient.cgColors)
        XCTAssertEqual(layer.startPoint, CGPoint(x: 0, y: 0.5))
        XCTAssertEqual(layer.endPoint, CGPoint(x: 1, y: 0.5))
        XCTAssertEqual(layer.locations, [0, 1])
    }

    func test_configureWithNilGradient_clearsColorsLeavingBackground() {
        let subject = GradientView()
        subject.backgroundColor = .green
        subject.configure(gradient: Gradient(colors: [.red, .blue]))

        subject.configure(gradient: nil)

        let layer = subject.layer as? CAGradientLayer
        XCTAssertNil(layer?.colors)
        XCTAssertEqual(subject.backgroundColor, .green)
    }

    /// The gradient tracks the bounds automatically, unlike a manually inserted sublayer.
    func test_layerFrame_followsBounds() {
        let subject = GradientView()

        subject.frame = CGRect(x: 0, y: 0, width: 120, height: 40)
        subject.layoutIfNeeded()

        XCTAssertEqual(subject.layer.bounds.size, CGSize(width: 120, height: 40))
    }
}
