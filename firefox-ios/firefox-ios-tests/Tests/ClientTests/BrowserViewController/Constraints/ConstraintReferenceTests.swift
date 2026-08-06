// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class ConstraintReferenceTests: XCTestCase {
    var parentView: UIView!
    var childView: UIView!

    override func setUp() async throws {
        try await super.setUp()
        parentView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        childView = UIView()
        parentView.addSubview(childView)
    }

    override func tearDown() async throws {
        childView = nil
        parentView = nil
        try await super.tearDown()
    }

    // MARK: - Native NSLayoutConstraint Tests

    func test_nativeConstraint_initialization() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor)
        let reference = ConstraintReference(native: constraint)
        XCTAssertNotNil(reference.layoutConstraint)
    }

    func test_nativeConstraint_updateOffset_changesConstant() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor)
        constraint.isActive = true
        let reference = ConstraintReference(native: constraint)
        reference.update(offset: 50)

        XCTAssertEqual(constraint.constant, 50)
    }

    func test_nativeConstraint_layoutConstraint_returnsOriginalConstraint() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor)
        let reference = ConstraintReference(native: constraint)
        let retrievedConstraint = reference.layoutConstraint

        XCTAssertTrue(constraint === retrievedConstraint)
    }

    // MARK: - Edge Cases

    func test_updateOffset_withZero_setsConstantToZero() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 100)
        constraint.isActive = true
        let reference = ConstraintReference(native: constraint)
        reference.update(offset: 0)

        XCTAssertEqual(constraint.constant, 0)
    }

    func test_updateOffset_withNegativeValue_acceptsNegativeOffset() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor)
        constraint.isActive = true
        let reference = ConstraintReference(native: constraint)
        reference.update(offset: -30)

        XCTAssertEqual(constraint.constant, -30)
    }

    func test_multipleUpdates_lastValueWins() {
        childView.translatesAutoresizingMaskIntoConstraints = false
        let constraint = childView.topAnchor.constraint(equalTo: parentView.topAnchor)
        constraint.isActive = true
        let reference = ConstraintReference(native: constraint)
        reference.update(offset: 10)
        reference.update(offset: 20)
        reference.update(offset: 30)

        XCTAssertEqual(constraint.constant, 30)
    }
}
