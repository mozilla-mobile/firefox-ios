// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import TestKit
import XCTest

@testable import Client

final class RemoteSettingsServiceSyncCoordinatorTests: XCTestCase {
    private var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        mockNotificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        mockNotificationCenter = nil
        super.tearDown()
    }

    func test_performSync_withAdBlockerUpdate_postsNotification() {
        let mockService = MockRemoteSettingsService(
            syncResult: ["tracking-protection-lists-ios"]
        )
        let subject = RemoteSettingsServiceSyncCoordinator(
            service: mockService,
            prefs: MockProfilePrefs(),
            notificationCenter: mockNotificationCenter
        )

        subject.forceImmediateSync()

        XCTAssertEqual(mockNotificationCenter.postCallCount, 1)
        XCTAssertEqual(mockNotificationCenter.savePostName, .remoteSettingsDidSync)
        let collections = mockNotificationCenter.saveUserInfo as? [String: [String]]
        XCTAssertEqual(
            collections?["updatedCollections"],
            ["tracking-protection-lists-ios"]
        )
    }

    func test_performSync_withOtherCollectionUpdate_postsNotificationWithCorrectCollections() {
        let mockService = MockRemoteSettingsService(
            syncResult: ["search-config-icons"]
        )
        let subject = RemoteSettingsServiceSyncCoordinator(
            service: mockService,
            prefs: MockProfilePrefs(),
            notificationCenter: mockNotificationCenter
        )

        subject.forceImmediateSync()

        XCTAssertEqual(mockNotificationCenter.postCallCount, 1)
        let collections = mockNotificationCenter.saveUserInfo as? [String: [String]]
        XCTAssertEqual(collections?["updatedCollections"], ["search-config-icons"])
    }

    func test_performSync_withEmptyResults_doesNotPostNotification() {
        let mockService = MockRemoteSettingsService(syncResult: [])
        let subject = RemoteSettingsServiceSyncCoordinator(
            service: mockService,
            prefs: MockProfilePrefs(),
            notificationCenter: mockNotificationCenter
        )

        subject.forceImmediateSync()

        XCTAssertEqual(mockNotificationCenter.postCallCount, 0)
    }
}
