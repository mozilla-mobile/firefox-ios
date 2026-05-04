// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import TabDataStore
import WebKit
import Shared
import Common
@testable import Client

final class TabManagerPreserveTabsTests: TabManagerTestsBase {
    // MARK: - selectTab preservation

    @MainActor
    func testSelectTab_immediatePreservationTrue_callsSaveWithForcedTrue() async throws {
        let tabs = generateTabs(count: 2)
        let subject = createSubject(tabs: tabs)
        subject.tabRestoreHasFinished = true
        subject.selectTab(tabs[1], previous: tabs[0], immediatePreservation: true)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataForcedValue, true)
    }

    @MainActor
    func testSelectTab_immediatePreservationFalse_callsSaveWithForcedFalse() async throws {
        let tabs = generateTabs(count: 2)
        let subject = createSubject(tabs: tabs)
        subject.tabRestoreHasFinished = true
        subject.selectTab(tabs[1], previous: tabs[0], immediatePreservation: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataForcedValue, false)
    }

    // MARK: - Save tabs

    @MainActor
    func testPreserveTabsWithNoTabs() async throws {
        let subject = createSubject()
        subject.preserveTabs(immediate: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 0)
        XCTAssertEqual(subject.tabs.count, 0)
    }

    @MainActor
    func testPreserveTabsWithOneTab() async throws {
        let subject = createSubject(tabs: generateTabs(count: 1))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs(immediate: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 1)
    }

    @MainActor
    func testPreserveTabsWithManyTabs() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs(immediate: false)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(subject.tabs.count, 5)
    }

    @MainActor
    func testPreserveTabsImmediate_callsSaveWithForcedTrue() async throws {
        let subject = createSubject(tabs: generateTabs(count: 1))
        subject.tabRestoreHasFinished = true
        subject.preserveTabs(immediate: true)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 1)
        XCTAssertEqual(mockTabStore.saveWindowDataForcedValue, true)
    }

    @MainActor
    func testPreserveTabsImmediate_beforeRestoreFinished_doesNotSave() async throws {
        let subject = createSubject(tabs: generateTabs(count: 1))
        subject.tabRestoreHasFinished = false
        subject.preserveTabs(immediate: true)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockTabStore.saveWindowDataCalledCount, 0)
        XCTAssertEqual(mockTabStore.saveWindowDataForcedValue, false)
    }

    // MARK: - Save preview screenshot

    @MainActor
    func testSaveScreenshotWithNoImage() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }

        subject.tabDidSetScreenshot(tab)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 0)
    }

    @MainActor
    func testSaveScreenshotWithImage() async throws {
        let subject = createSubject(tabs: generateTabs(count: 5))
        guard let tab = subject.tabs.first else {
            XCTFail("First tab was expected to be found")
            return
        }
        tab.setScreenshot(UIImage())
        subject.tabDidSetScreenshot(tab)
        try await Task.sleep(nanoseconds: sleepTime)
        XCTAssertEqual(mockDiskImageStore.saveImageForKeyCallCount, 1)
    }
}
