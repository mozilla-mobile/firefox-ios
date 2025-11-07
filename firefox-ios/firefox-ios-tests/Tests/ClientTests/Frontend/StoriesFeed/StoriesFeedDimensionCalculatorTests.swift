// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class StoriesFeedDimensionCalculatorTests: XCTestCase {
    struct DeviceSize {
        static let iPhone17PortraitWidth: CGFloat = 402
        static let iPhone17LandscapeSafeAreaWidth: CGFloat = 750
        static let iPhone17ProMaxPortraitWidth: CGFloat = 440
        static let iPhone17ProMaxLandscapeSafeAreaWidth: CGFloat = 832
        static let iPhoneSEPortraitWidth: CGFloat = 320
        static let iPhoneSELandscapeWidth: CGFloat = 568
        static let iPadPro13InPortrait: CGFloat = 1032
        static let iPadPro13InLandscape: CGFloat = 1376
    }

    func test_numberOfCellsThatFit_withIphone17Portrait_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhone17PortraitWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 1)
    }

    func test_numberOfCellsThatFit_withIphone17Landscape_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhone17LandscapeSafeAreaWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 1)
    }

    func test_numberOfCellsThatFit_withIphone17ProMaxPortrait_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhone17ProMaxPortraitWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 1)
    }

    func test_numberOfCellsThatFit_withIphone17ProMaxLandscape_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhone17ProMaxLandscapeSafeAreaWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 2)
    }

    func test_numberOfCellsThatFit_withIphoneSePortrait_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhoneSEPortraitWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 1)
    }

    func test_numberOfCellsThatFit_witIhphoneSeLandscape_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPhoneSELandscapeWidth
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 1)
    }

    func test_numberOfCellsThatFit_withIpad13InPortrait_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPadPro13InPortrait
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 2)
    }

    func test_numberOfCellsThatFit_withIpad13InLandscape_returnsExpectedCellCount() {
        let deviceSize = DeviceSize.iPadPro13InLandscape
        let cellCount = StoriesFeedDimensionCalculator.numberOfCellsThatFit(in: deviceSize)
        XCTAssertEqual(cellCount, 3)
    }

    func test_horizontalInset_withIphone17Portrait_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhone17PortraitWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 1)
        XCTAssertEqual(horizontalInset, 20.5)
    }

    func test_horizontalInset_withIphone17Landscape_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhone17LandscapeSafeAreaWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 1)
        XCTAssertEqual(horizontalInset, 194.5)
    }

    func test_horizontalInset_withIphone17ProMaxPortrait_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhone17ProMaxPortraitWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 1)
        XCTAssertEqual(horizontalInset, 39.5)
    }

    func test_horizontalInset_withIphone17ProMaxLandscape_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhone17ProMaxLandscapeSafeAreaWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 2)
        XCTAssertEqual(horizontalInset, 45)
    }

    func test_horizontalInset_withIphoneSePortrait_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhoneSEPortraitWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 1)
        XCTAssertEqual(horizontalInset, 16)
    }

    func test_horizontalInset_witIhphoneSeLandscape_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPhoneSELandscapeWidth
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 1)
        XCTAssertEqual(horizontalInset, 103.5)
    }

    func test_horizontalInset_withIpad13InPortrait_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPadPro13InPortrait
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 2)
        XCTAssertEqual(horizontalInset, 145)
    }

    func test_horizontalInset_withIpad13InLandscape_returnsExpectedValue() {
        let deviceSize = DeviceSize.iPadPro13InLandscape
        let horizontalInset = StoriesFeedDimensionCalculator.horizontalInset(for: deviceSize, cellCount: 3)
        XCTAssertEqual(horizontalInset, 126.5)
    }
}
