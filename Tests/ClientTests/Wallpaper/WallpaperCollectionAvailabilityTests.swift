// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperCollectionAvailabilityTests: XCTestCase {

    func testFullAvailability() {
        let sut = WallpaperCollectionAvailability(start: nil, end: nil)
        XCTAssertTrue(sut.isAvailable, "Wallpaper collection should be available")
    }

    func testNoEndDate() {
        let sut = WallpaperCollectionAvailability(start: Date.yesterday, end: nil)
        XCTAssertTrue(sut.isAvailable, "Wallpaper collection should be available")
    }

    func testNoStartDate() {
        let sut = WallpaperCollectionAvailability(start: nil, end: Date.tomorrow)
        XCTAssertTrue(sut.isAvailable, "Wallpaper collection should be available")
    }

    func testStartDateInFuture() {
        let sut = WallpaperCollectionAvailability(start: Date.tomorrow, end: nil)
        XCTAssertFalse(sut.isAvailable, "Wallpaper collection should not be available")
    }

    func testPastEndDate() {
        let sut = WallpaperCollectionAvailability(start: nil, end: Date.yesterday)
        XCTAssertFalse(sut.isAvailable, "Wallpaper collection should not be available")
    }

}
