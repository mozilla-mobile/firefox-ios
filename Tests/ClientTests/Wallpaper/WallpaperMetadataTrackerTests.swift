// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

import XCTest

@testable import Client

class WallpaperMetadataTrackerTests: XCTestCase {

    // MARK: - Properties
    var sut: WallpaperMetadataTracker!
    var mockUserDefaults: MockUserDefaults!

    private let prefsKey = PrefsKeys.Wallpapers.MetadataLastCheckedDate

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockUserDefaults = MockUserDefaults()
        sut = WallpaperMetadataTracker(with: mockUserDefaults)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockUserDefaults = nil
        try super.tearDownWithError()
    }

    // MARK: Tests
    func testMetadataTracker_whenInitializedFirstTime_fetchesFreshData() async {
        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()

        XCTAssertTrue(didFetchNewMetadata)
    }

    func testMetadataTracker_checkingOnSameDay_returnsFalse() async {
        let todaysDate = Calendar.current.startOfDay(for: Date())
        mockUserDefaults.set(todaysDate, forKey: prefsKey)

        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()

        XCTAssertFalse(didFetchNewMetadata)
    }

    func testMetadataTracker_checkingOnNextDay_returnsTrue() async {
        let currentDate = Date()
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
            XCTFail("Failed creating required date")
            return
        }
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        mockUserDefaults.set(startOfYesterday, forKey: prefsKey)

        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()

        XCTAssertTrue(didFetchNewMetadata)
    }
}
