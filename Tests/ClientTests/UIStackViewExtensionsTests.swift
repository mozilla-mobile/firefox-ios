// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

@testable import Client

class UIStackViewExtensionsTests: XCTestCase {

    // MARK: Top

    func testAddArrangedViewToTop_whenEmpty() {
        let stackView = UIStackView()
        let view = UIView()
        stackView.addArrangedViewToTop(view)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
    }

    func testAddArrangedViewToTop_withTwoViews() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.addArrangedViewToTop(firstView)
        stackView.addArrangedViewToTop(secondView)

        XCTAssertEqual(stackView.arrangedSubviews[0], secondView)
        XCTAssertEqual(stackView.arrangedSubviews[1], firstView)
    }

    func testAddArrangedViewToTop_thenRemove() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.addArrangedViewToTop(firstView)
        stackView.addArrangedViewToTop(secondView)
        stackView.removeArrangedView(firstView)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
        XCTAssertEqual(stackView.arrangedSubviews[0], secondView)
    }

    func testAddArrangedViewToTop_thenRemoveAll() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.addArrangedViewToTop(firstView)
        stackView.addArrangedViewToTop(secondView)
        stackView.removeAllArrangedViews()

        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    // MARK: Bottom

    func testAddArrangedViewToBottom_whenEmpty() {
        let stackView = UIStackView()
        let view = UIView()
        stackView.addArrangedViewToBottom(view)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
    }

    func testAddArrangedViewToBottom_withTwoViews() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.addArrangedViewToBottom(firstView)
        stackView.addArrangedViewToBottom(secondView)

        XCTAssertEqual(stackView.arrangedSubviews[0], firstView)
        XCTAssertEqual(stackView.arrangedSubviews[1], secondView)
    }

    // MARK: Insert

    func testInsertArrangedView_whenEmptyAt0() {
        let stackView = UIStackView()
        let view = UIView()
        stackView.insertArrangedView(view, position: 0)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
    }

    func testInsertArrangedView_lessThan0DoesNothing() {
        let stackView = UIStackView()
        let view = UIView()
        stackView.insertArrangedView(view, position: -1)

        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    func testInsertArrangedView_greaterThanCountDoesNothing() {
        let stackView = UIStackView()
        let view = UIView()
        stackView.insertArrangedView(view, position: 5)

        XCTAssertEqual(stackView.arrangedSubviews.count, 0)
    }

    func testInsertArrangezdView_insertAtSubsequentPosition() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.insertArrangedView(firstView, position: 0)
        stackView.insertArrangedView(secondView, position: 1)

        XCTAssertEqual(stackView.arrangedSubviews.count, 2)
    }

    func testInsertArrangedView_insertAtSamePosition() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.insertArrangedView(firstView, position: 0)
        stackView.insertArrangedView(secondView, position: 0)

        XCTAssertEqual(stackView.arrangedSubviews.count, 2)
    }

    func testInsertArrangedView_insertOneTooFar() {
        let stackView = UIStackView()
        let firstView = UIView()
        let secondView = UIView()
        stackView.insertArrangedView(firstView, position: 0)
        stackView.insertArrangedView(secondView, position: 2)

        XCTAssertEqual(stackView.arrangedSubviews.count, 1)
    }
}
