// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

import XCTest

@testable import Client

class MockWallpaperStorageUtility: WallpaperStorageProtocol, WallpaperMetadataTestProvider {
    var fetchMetadataCalled = 0

    func fetchMetadata() throws -> WallpaperMetadata? {
        fetchMetadataCalled += 1
        return getExpectedMetadata(for: .newUpdates)
    }
}

class WallpaperMetadataTrackerTests: XCTestCase, WallpaperJSONTestProvider {
    // MARK: - Properties
    var sut: WallpaperMetadataUtility!
    var mockUserDefaults: MockUserDefaults!
    var mockNetwork: NetworkingMock!

    private let prefsKey = PrefsKeys.Wallpapers.MetadataLastCheckedDate

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockUserDefaults = MockUserDefaults()
        mockNetwork = NetworkingMock()
        sut = WallpaperMetadataUtility(
            with: mockNetwork,
            and: mockUserDefaults,
            storageUtility: MockWallpaperStorageUtility()
        )
    }

    override func tearDown() {
        sut = nil
        mockUserDefaults = nil
        mockNetwork = nil
        super.tearDown()
    }

    // MARK: Tests
    func testMetadataTracker_whenInitializedFirstTime_fetchesFreshData() async {
        setupNetwork(for: .goodData)
        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()

        XCTAssertTrue(didFetchNewMetadata)
    }

    func testMetadataTracker_checkingOnSameDay_returnsFalse() async {
        let todaysDate = Calendar.current.startOfDay(for: Date())
        mockUserDefaults.set(todaysDate, forKey: prefsKey)

        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()

        XCTAssertFalse(didFetchNewMetadata)
    }

//    func testMetadataTracker_checkingOnNextDay_returnsTrue() async {
//        setupNetwork(for: .goodData)
//        let currentDate = Date()
//        let calendar = Calendar.current
//        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
//            XCTFail("Failed creating required date")
//            return
//        }
//        let startOfYesterday = calendar.startOfDay(for: yesterday)
//        mockUserDefaults.set(startOfYesterday, forKey: prefsKey)
//
//        let didFetchNewMetadata = await sut.metadataUpdateFetchedNewData()
//
//        XCTAssertTrue(didFetchNewMetadata)
//    }

    private func setupNetwork(for dataType: WallpaperJSONId) {
        let data = getDataFromJSONFile(named: dataType)
        mockNetwork.result = .success(data)
    }
}
