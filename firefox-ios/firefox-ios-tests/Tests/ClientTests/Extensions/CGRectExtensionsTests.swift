// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class CGRectExtensionsTests: XCTestCase {
    // MARK: - init(width:height:)

    func testInitWithWidthHeight_createsRectAtOrigin() {
        let rect = CGRect(width: 100, height: 50)

        XCTAssertEqual(rect.origin.x, 0)
        XCTAssertEqual(rect.origin.y, 0)
        XCTAssertEqual(rect.size.width, 100)
        XCTAssertEqual(rect.size.height, 50)
    }

    func testInitWithWidthHeight_withZeroValues() {
        let rect = CGRect(width: 0, height: 0)

        XCTAssertEqual(rect, .zero)
    }

    func testInitWithWidthHeight_withNegativeValues() {
        let rect = CGRect(width: -10, height: -20)

        XCTAssertEqual(rect.size.width, -10)
        XCTAssertEqual(rect.size.height, -20)
    }

    // MARK: - init(size:)

    func testInitWithSize_createsRectAtZeroOrigin() {
        let size = CGSize(width: 200, height: 150)
        let rect = CGRect(size: size)

        XCTAssertEqual(rect.origin, .zero)
        XCTAssertEqual(rect.size, size)
    }

    func testInitWithSize_withEmptySize() {
        let rect = CGRect(size: .zero)

        XCTAssertEqual(rect, .zero)
    }

    // MARK: - center (getter)

    func testCenterGetter_returnsCorrectCenter() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

        let center = rect.center

        XCTAssertEqual(center.x, 50)
        XCTAssertEqual(center.y, 25)
    }

    func testCenterGetter_withNonZeroOrigin() {
        let rect = CGRect(x: 20, y: 30, width: 100, height: 50)

        let center = rect.center

        // Center should be relative to size, not absolute position
        XCTAssertEqual(center.x, 50)
        XCTAssertEqual(center.y, 25)
    }

    func testCenterGetter_withZeroRect() {
        let rect = CGRect.zero

        let center = rect.center

        XCTAssertEqual(center, .zero)
    }

    // MARK: - center (setter)

    func testCenterSetter_updatesOrigin() {
        var rect = CGRect(x: 0, y: 0, width: 100, height: 50)

        rect.center = CGPoint(x: 150, y: 100)

        // Origin should be adjusted so center is at (150, 100)
        XCTAssertEqual(rect.origin.x, 100) // 150 - 50 (half width)
        XCTAssertEqual(rect.origin.y, 75)  // 100 - 25 (half height)
        XCTAssertEqual(rect.size.width, 100)
        XCTAssertEqual(rect.size.height, 50)
    }

    func testCenterSetter_preservesSize() {
        var rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        let originalSize = rect.size

        rect.center = CGPoint(x: 50, y: 50)

        XCTAssertEqual(rect.size, originalSize)
    }

    func testCenterSetter_withZeroCenter() {
        var rect = CGRect(x: 100, y: 100, width: 80, height: 60)

        rect.center = .zero

        // Expected 80 / 2 = 40
        XCTAssertEqual(rect.origin.x, -40)
        // Expected 60 / 2 = 30
        XCTAssertEqual(rect.origin.y, -30)
    }

    // MARK: - updateWidth(byPercentage:)

    func testUpdateWidth_with100Percent_returnsOriginalWidth() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)

        let updated = rect.updateWidth(byPercentage: 1.0)

        XCTAssertEqual(updated.size.width, 100)
        XCTAssertEqual(updated.origin, rect.origin)
        XCTAssertEqual(updated.size.height, rect.size.height)
    }

    func testUpdateWidth_with50Percent_halvesWidth() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 50)

        let updated = rect.updateWidth(byPercentage: 0.5)

        XCTAssertEqual(updated.size.width, 50)
        XCTAssertEqual(updated.origin, rect.origin)
        XCTAssertEqual(updated.size.height, rect.size.height)
    }

    func testUpdateWidth_with200Percent_doublesWidth() {
        let rect = CGRect(x: 5, y: 10, width: 50, height: 30)

        let updated = rect.updateWidth(byPercentage: 2.0)

        XCTAssertEqual(updated.size.width, 100)
        XCTAssertEqual(updated.origin, rect.origin)
        XCTAssertEqual(updated.size.height, rect.size.height)
    }

    func testUpdateWidth_withZeroPercent_returnsZeroWidth() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

        let updated = rect.updateWidth(byPercentage: 0.0)

        XCTAssertEqual(updated.size.width, 0)
        XCTAssertEqual(updated.size.height, rect.size.height)
    }

    func testUpdateWidth_preservesOriginAndHeight() {
        let rect = CGRect(x: 25, y: 35, width: 80, height: 60)

        let updated = rect.updateWidth(byPercentage: 0.75)

        XCTAssertEqual(updated.origin.x, 25)
        XCTAssertEqual(updated.origin.y, 35)
        XCTAssertEqual(updated.size.height, 60)
        // Expected 80 * 0.75 = 60
        XCTAssertEqual(updated.size.width, 60)
    }

    func testUpdateWidth_withNegativePercentage() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)

        let updated = rect.updateWidth(byPercentage: -0.5)

        XCTAssertEqual(updated.size.width, -50)
    }

    // MARK: - Integration Tests

    func testCombinedOperations_initWithSizeThenUpdateCenter() {
        var rect = CGRect(size: CGSize(width: 100, height: 50))
        rect.center = CGPoint(x: 200, y: 100)

        XCTAssertEqual(rect.origin.x, 150)
        XCTAssertEqual(rect.origin.y, 75)
        XCTAssertEqual(rect.size.width, 100)
        XCTAssertEqual(rect.size.height, 50)
    }

    func testCombinedOperations_updateWidthThenGetCenter() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let updated = rect.updateWidth(byPercentage: 0.5)

        let center = updated.center

        // Half of new width and height (50)
        XCTAssertEqual(center.x, 25)
        XCTAssertEqual(center.y, 25)
    }
}
