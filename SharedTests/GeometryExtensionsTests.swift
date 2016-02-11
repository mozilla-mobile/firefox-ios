/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
import UIKit
@testable import Shared

class GeometryExtensionsTests: XCTestCase {

    let targetSize = CGSize(width: 100, height: 100)

    func testBestFitSizeForNoSizes() {
        XCTAssertNil(targetSize.sizeThatBestFitsFromSizes([]))
    }

    func testBestFitSizeForOneSize() {
        let sizes = [CGSize(width: 50, height: 50)]
        XCTAssertEqual(targetSize.sizeThatBestFitsFromSizes(sizes)!, sizes.first!)
    }

    func testBestFitSizeForVariousSquareSizes() {
        let sizes = [
            CGSize(width: 20, height: 20),
            CGSize(width: 50, height: 50),
            CGSize(width: 90, height: 90),
            CGSize(width: 120, height: 120),
            CGSize(width: 130, height: 130),
        ]
        XCTAssertEqual(targetSize.sizeThatBestFitsFromSizes(sizes)!, CGSize(width: 90, height: 90))
    }

    func testBestFitSizeForVariousRectangleSizes() {
        let sizes = [
            CGSize(width: 100, height: 20),
            CGSize(width: 50, height: 50),
            CGSize(width: 110, height: 70),
            CGSize(width: 1, height: 1),
            CGSize(width: 90, height: 120),
        ]
        XCTAssertEqual(targetSize.sizeThatBestFitsFromSizes(sizes)!, CGSize(width: 90, height: 120))
    }
}
