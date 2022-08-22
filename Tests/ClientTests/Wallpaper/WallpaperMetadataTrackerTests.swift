// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

import XCTest

@testable import Client

class WallpaperMetadataTrackerTests: XCTestCase {

    // MARK: - Properties
    var sut: WallpaperMetadataTracker!
    var mockUserDefaults: MockUserDefaults!

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        sut = nil
        mockUserDefaults = nil
        try super.tearDownWithError()
    }

    // MARK: Tests
    func testMetadataTracker_whenInitializedFirstTime_fetchesFreshData() {
        mockUserDefaults = MockUserDefaults()
        sut = WallpaperMetadataTracker(with: mockUserDefaults)

        XCTAssertTrue(sut.shouldCheckForNewMetadata)
    }
}
