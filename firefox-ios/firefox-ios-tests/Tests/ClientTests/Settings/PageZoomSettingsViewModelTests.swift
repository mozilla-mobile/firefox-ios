// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Storage
import XCTest
@testable import Client

@MainActor
final class PageZoomSettingsViewModelTests: XCTestCase {
    private var zoomManager: ZoomPageManager!
    private var notificationCenter: MockNotificationCenter!
    private var zoomStore: MockZoomStore!
    private let windowUUID: WindowUUID = .XCTestDefaultUUID
    private let domainZoomLevels = [
        DomainZoomLevel(host: "example.com", zoomLevel: 0.90),
        DomainZoomLevel(host: "example1.com", zoomLevel: 0.75),
        DomainZoomLevel(host: "example2.com", zoomLevel: 1.10),
    ]

    override func setUp() async throws {
        try await super.setUp()
        self.zoomStore = MockZoomStore()
        self.zoomManager = ZoomPageManager(windowUUID: windowUUID, zoomStore: zoomStore)
        self.notificationCenter = MockNotificationCenter()
    }

    override func tearDown() async throws {
        self.zoomManager = nil
        self.notificationCenter = nil
        self.zoomStore = nil
        try await super.tearDown()
    }

    func test_isInitializedCorrectly() {
        let subject = createSubject()

        zoomStore.storeZoomLevels = domainZoomLevels
        XCTAssertEqual(subject.zoomManager.getDomainLevel().count, zoomStore.storeZoomLevels.count)
    }

    func test_updateDefaultZoom_IsCalled() {
        let subject = createSubject()

        let expectedZoomLevel = ZoomLevel.fiftyPercent

        zoomStore.savedDefaultZoom = expectedZoomLevel.rawValue
        subject.updateDefaultZoomLevel(newValue: ZoomLevel.fiftyPercent)
        XCTAssertEqual(subject.zoomManager.zoomStore.getDefaultZoom(), expectedZoomLevel.rawValue)
    }

    func test_updateDefaultZoom_postsNotification() {
        let subject = createSubject()

        subject.updateDefaultZoomLevel(newValue: .oneHundredFiftyPercent)

        XCTAssertEqual(notificationCenter.postCallCount, 1)
        XCTAssertEqual(notificationCenter.savePostName, .PageZoomSettingsChanged)
    }

    func test_updateDefaultZoom_withDifferentZoomLevels() {
        let subject = createSubject()
        let testCases: [ZoomLevel] = [
            .fiftyPercent,
            .seventyFivePercent,
            .oneHundredPercent,
            .oneHundredTwentyFivePercent,
            .oneHundredFiftyPercent,
            .twoHundredPercent,
            .threeHundredPercent
        ]

        for zoomLevel in testCases {
            subject.updateDefaultZoomLevel(newValue: zoomLevel)
            XCTAssertEqual(subject.zoomManager.zoomStore.getDefaultZoom(), zoomLevel.rawValue)
        }
    }

    // MARK: - resetDomainZoomLevel

    func test_resetDomainZoomLevel_removesAllLevels() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.resetDomainZoomLevel()

        XCTAssertTrue(subject.domainZoomLevels.isEmpty)
        XCTAssertTrue(zoomStore.storeZoomLevels.isEmpty)
    }

    func test_resetDomainZoomLevel_postsNotification() {
        let subject = createSubject()

        subject.resetDomainZoomLevel()

        XCTAssertEqual(notificationCenter.postCallCount, 1)
        XCTAssertEqual(notificationCenter.savePostName, .PageZoomSettingsChanged)
    }

    func test_resetDomainZoomLevel_whenAlreadyEmpty() {
        zoomStore.storeZoomLevels = []
        let subject = createSubject()

        subject.resetDomainZoomLevel()

        XCTAssertTrue(subject.domainZoomLevels.isEmpty)
        XCTAssertEqual(notificationCenter.postCallCount, 1)
    }

    // MARK: - deleteZoomLevel

    func test_deleteZoomLevel_removesItemAtIndex() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 1))

        XCTAssertEqual(subject.domainZoomLevels.count, 2)
        XCTAssertEqual(subject.domainZoomLevels[0].host, "example.com")
        XCTAssertEqual(subject.domainZoomLevels[1].host, "example2.com")
    }

    func test_deleteZoomLevel_deletesFromStore() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 0))

        XCTAssertEqual(zoomStore.storeZoomLevels.count, 2)
        XCTAssertFalse(zoomStore.storeZoomLevels.contains(where: { $0.host == "example.com" }))
    }

    func test_deleteZoomLevel_postsNotification() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 0))

        XCTAssertEqual(notificationCenter.postCallCount, 1)
        XCTAssertEqual(notificationCenter.savePostName, .PageZoomSettingsChanged)
    }

    func test_deleteZoomLevel_withEmptyIndexSet() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet())

        XCTAssertEqual(subject.domainZoomLevels.count, 3)
        XCTAssertEqual(notificationCenter.postCallCount, 0)
    }

    func test_deleteZoomLevel_deletesFirstItem() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 0))

        XCTAssertEqual(subject.domainZoomLevels.count, 2)
        XCTAssertEqual(subject.domainZoomLevels[0].host, "example1.com")
        XCTAssertEqual(subject.domainZoomLevels[1].host, "example2.com")
    }

    func test_deleteZoomLevel_deletesLastItem() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 2))

        XCTAssertEqual(subject.domainZoomLevels.count, 2)
        XCTAssertEqual(subject.domainZoomLevels[0].host, "example.com")
        XCTAssertEqual(subject.domainZoomLevels[1].host, "example1.com")
    }

    func test_deleteZoomLevel_multipleItems() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.deleteZoomLevel(at: IndexSet(integer: 1))
        subject.deleteZoomLevel(at: IndexSet(integer: 0))

        XCTAssertEqual(subject.domainZoomLevels.count, 1)
        XCTAssertEqual(subject.domainZoomLevels[0].host, "example2.com")
    }

    // MARK: - Integration Tests

    func test_domainZoomLevels_isPublished() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        let initialCount = subject.domainZoomLevels.count
        XCTAssertEqual(initialCount, 3)

        subject.deleteZoomLevel(at: IndexSet(integer: 0))
        XCTAssertEqual(subject.domainZoomLevels.count, 2)
    }

    func test_multipleOperations_maintainConsistency() {
        zoomStore.storeZoomLevels = domainZoomLevels
        let subject = createSubject()

        subject.updateDefaultZoomLevel(newValue: .twoHundredPercent)
        subject.deleteZoomLevel(at: IndexSet(integer: 0))
        subject.resetDomainZoomLevel()

        XCTAssertTrue(subject.domainZoomLevels.isEmpty)
        XCTAssertEqual(subject.zoomManager.zoomStore.getDefaultZoom(), ZoomLevel.twoHundredPercent.rawValue)
        XCTAssertEqual(notificationCenter.postCallCount, 3)
    }

    // MARK: - Private Helpers

    private func createSubject() -> PageZoomSettingsViewModel {
        let subject = PageZoomSettingsViewModel(zoomManager: zoomManager,
                                                notificationCenter: notificationCenter)
        trackForMemoryLeaks(subject)
        return subject
    }
}
