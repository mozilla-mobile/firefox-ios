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
        XCTAssertEqual(cellCount, 2)
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

    func test_numberOfCellsThatFit_withIphoneSeLandscape_returnsExpectedCellCount() {
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
}
