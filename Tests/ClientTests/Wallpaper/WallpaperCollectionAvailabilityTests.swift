// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperCollectionAvailabilityTests: XCTestCase {
    func testFullAvailability() {
        let subject = WallpaperCollectionAvailability(start: nil, end: nil)
        XCTAssertTrue(subject.isAvailable, "Wallpaper collection should be available")
    }

    func testNoEndDate() {
        let subject = WallpaperCollectionAvailability(start: Date.yesterday, end: nil)
        XCTAssertTrue(subject.isAvailable, "Wallpaper collection should be available")
    }

    func testNoStartDate() {
        let subject = WallpaperCollectionAvailability(start: nil, end: Date.tomorrow)
        XCTAssertTrue(subject.isAvailable, "Wallpaper collection should be available")
    }

    func testStartDateInFuture() {
        let subject = WallpaperCollectionAvailability(start: Date.tomorrow, end: nil)
        XCTAssertFalse(subject.isAvailable, "Wallpaper collection should not be available")
    }

    func testPastEndDate() {
        let subject = WallpaperCollectionAvailability(start: nil, end: Date.yesterday)
        XCTAssertFalse(subject.isAvailable, "Wallpaper collection should not be available")
    }
}
