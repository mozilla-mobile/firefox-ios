// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Common

final class UIViewExtensionTests: XCTestCase {
    final class CustomView: UIView {
        var customProperty: String

        init(customProperty: String) {
            self.customProperty = customProperty
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    // MARK: - 'build` method tests
    func test_defaultInitialization() {
        let view: UIView = .build()
        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints should be false by default.")
    }

    func test_builderClosure() {
        let view: UIView = .build { view in
            view.backgroundColor = .red
        }

        XCTAssertEqual(view.backgroundColor,
                       .red,
                       "The builder closure should configure the view's background color.")
        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints should be false by default.")
    }

    func test_customInitializer() {
        let customView: CustomView = .build(nil) {
            CustomView(customProperty: "TestValue")
        }

        XCTAssertEqual(customView.customProperty,
                       "TestValue",
                       "The custom initializer should properly initialize the custom property.")
        XCTAssertFalse(customView.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints should be false by default.")
    }

    func test_customInitializerAndBuilder() {
        let customView: CustomView = .build({ view in
            view.backgroundColor = .blue
        }, {
            CustomView(customProperty: "TestValue")
        })

        XCTAssertEqual(customView.customProperty,
                       "TestValue",
                       "The custom initializer should properly initialize the custom property.")
        XCTAssertEqual(customView.backgroundColor,
                       .blue,
                       "The builder closure should configure the view's background color.")
        XCTAssertFalse(customView.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints should be false by default.")
    }

    // MARK: - `addSubviews method tests
    func test_addMultipleSubviews() {
        let parentView = UIView()
        let subview1 = UIView()
        let subview2 = UIView()
        let subview3 = UIView()

        parentView.addSubviews(subview1, subview2, subview3)

        XCTAssertEqual(parentView.subviews.count, 3, "Parent view should have 3 subviews.")
        XCTAssertTrue(parentView.subviews.contains(subview1), "Subview1 should be added to the parent view.")
        XCTAssertTrue(parentView.subviews.contains(subview2), "Subview2 should be added to the parent view.")
        XCTAssertTrue(parentView.subviews.contains(subview3), "Subview3 should be added to the parent view.")
    }

    func test_addNoSubviews() {
        let parentView = UIView()

        parentView.addSubviews()

        XCTAssertTrue(parentView.subviews.isEmpty, "Parent view should have no subviews when none are added")
    }

    func test_addSameSubviewMultipleTimes() {
        let parentView = UIView()
        let subview = UIView()

        parentView.addSubviews(subview, subview)

        XCTAssertEqual(parentView.subviews.count, 1, "The same subview should not be added multiple times.")
        XCTAssertTrue(parentView.subviews.contains(subview), "Subview should be added to the parent view.")
    }

    // MARK: `pinToSuperView' method tests
    func test_pinToSuperview() {
        let parentView = UIView()
        let childView = UIView()

        parentView.addSubview(childView)
        childView.pinToSuperview()

        XCTAssertFalse(childView.translatesAutoresizingMaskIntoConstraints,
                       "translatesAutoresizingMaskIntoConstraints should be set to false.")
        XCTAssertEqual(parentView.constraints.count,
                       4,
                       "There should be 4 constraints added to the parent view.")

        let constraints = parentView.constraints
        XCTAssertTrue(constraints.contains(
            where: { $0.firstAnchor == childView.topAnchor && $0.secondAnchor == parentView.topAnchor }),
                      "Top anchor should be pinned to the parent's top anchor")
        XCTAssertTrue(constraints.contains(
            where: { $0.firstAnchor == childView.leadingAnchor && $0.secondAnchor == parentView.leadingAnchor }),
                      "Leading anchor should be pinned to the parent's leading anchor")
        XCTAssertTrue(constraints.contains(
            where: { $0.firstAnchor == childView.trailingAnchor && $0.secondAnchor == parentView.trailingAnchor }),
                      "Trailing anchor should be pinned to the parent's trailing anchor")
        XCTAssertTrue(constraints.contains(
            where: { $0.firstAnchor == childView.bottomAnchor && $0.secondAnchor == parentView.bottomAnchor }),
                      "Bottom anchor should be pinned to the parent's bottom anchor")
    }

    func test_pinToSuperviewWithoutSuperview() {
        let childView = UIView()

        childView.pinToSuperview()

        XCTAssertTrue(childView.translatesAutoresizingMaskIntoConstraints,
                      "translatesAutoresizingMaskIntoConstraints should remain true when there is no superview")
    }
}
