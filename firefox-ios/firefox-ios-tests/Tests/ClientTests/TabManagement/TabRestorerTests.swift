// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TabDataStore
import Common
@testable import Client

@MainActor
final class TabRestorerTests: XCTestCase {
    private var mockDataStore: MockTabDataStore!
    private var mockDelegate: MockTabRestorerDelegate!
    private var mockProfile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: mockProfile)
        mockDataStore = MockTabDataStore()
        mockDelegate = MockTabRestorerDelegate(profile: mockProfile)
    }

    override func tearDown() async throws {
        mockProfile = nil
        mockDataStore = nil
        mockDelegate = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testRestoreTabs_returnsEmptyResult_whenNoWindowData() async {
        let subject = createSubject()

        let result = await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertTrue(result.restoredTabs.isEmpty)
        XCTAssertNil(result.selectedTabUUID)
        XCTAssertEqual(result.windowUUID, WindowUUID.XCTestDefaultUUID)
    }

    func testRestoreTabs_returnsEmptyResult_whenAllTabsArePrivate() async {
        mockDataStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: [makeTabData(isPrivate: true), makeTabData(isPrivate: true)]
        )
        let subject = createSubject(shouldClearPrivateTabs: true)

        let result = await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertTrue(result.restoredTabs.isEmpty)
        XCTAssertNil(result.selectedTabUUID)
    }

    func testRestoreTabs_restoresNormalTabs() async {
        mockDataStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: [makeTabData(), makeTabData(), makeTabData()]
        )
        let subject = createSubject()

        let result = await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertEqual(result.restoredTabs.count, 3)
        XCTAssertEqual(mockDelegate.createdTabs.count, 3)
    }

    func testRestoreTabs_setsSelectedTabUUID_forActiveTab() async {
        let activeTabId = UUID()
        mockDataStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: activeTabId,
            tabData: [makeTabData(id: activeTabId), makeTabData()]
        )
        let subject = createSubject()

        let result = await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertEqual(result.selectedTabUUID, activeTabId.uuidString)
    }

    func testRestoreTabs_callsRestoreScreenshot_forEachRestoredTab() async {
        mockDataStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: [makeTabData(), makeTabData()]
        )
        let subject = createSubject()

        await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertEqual(mockDelegate.screenshotRestoredTabs.count, 2)
    }

    func testRestoreTabs_keepsPrivateTabs_whenClearPrivateTabsIsDisabled() async {
        mockDataStore.fetchTabWindowData = WindowData(
            id: UUID(),
            activeTabId: UUID(),
            tabData: [makeTabData(isPrivate: true), makeTabData(), makeTabData()]
        )
        let subject = createSubject(shouldClearPrivateTabs: false)

        let result = await subject.restoreTabs(for: .XCTestDefaultUUID)

        XCTAssertEqual(result.restoredTabs.count, 3)
    }

    // MARK: - Helpers

    private func createSubject(shouldClearPrivateTabs: Bool = true,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> DefaultTabRestorer {
        let subject = DefaultTabRestorer(
            delegate: mockDelegate,
            tabDataStore: mockDataStore,
            shouldClearPrivateTabs: shouldClearPrivateTabs
        )
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func makeTabData(id: UUID = UUID(), isPrivate: Bool = false) -> TabData {
        return TabData(
            id: id,
            title: "Firefox",
            siteUrl: "https://mozilla.com",
            faviconURL: nil,
            isPrivate: isPrivate,
            lastUsedTime: Date(),
            createdAtTime: Date(),
            temporaryDocumentSession: nil
        )
    }
}
