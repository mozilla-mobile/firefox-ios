// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import TestKit
import WebKit
import XCTest

@testable import Client

@MainActor
final class WebsiteDataManagementViewModelTests: XCTestCase {
    private var viewModelChangedCallCount = 0
    private var selectionChangedCallCount = 0

    override func setUp() async throws {
        try await super.setUp()
        viewModelChangedCallCount = 0
        selectionChangedCallCount = 0
    }

    func test_selectItem_notifiesSelectionChangedOnly() {
        let subject = createSubject()
        let record = MockWebsiteDataRecord(displayName: "mozilla.org")

        subject.selectItem(record)

        XCTAssertEqual(selectionChangedCallCount, 1)
        XCTAssertEqual(viewModelChangedCallCount, 0)
    }

    func test_deselectItem_notifiesSelectionChangedOnly() {
        let subject = createSubject()
        let record = MockWebsiteDataRecord(displayName: "mozilla.org")

        subject.selectItem(record)
        subject.deselectItem(record)

        XCTAssertEqual(selectionChangedCallCount, 2)
        XCTAssertEqual(viewModelChangedCallCount, 0)
    }

    func test_selectItem_addsRecordToSelection() {
        let subject = createSubject()
        let firstRecord = MockWebsiteDataRecord(displayName: "mozilla.org")
        let secondRecord = MockWebsiteDataRecord(displayName: "example.com")

        subject.selectItem(firstRecord)
        subject.selectItem(secondRecord)

        XCTAssertEqual(subject.selectedRecords.count, 2)
        XCTAssertTrue(subject.selectedRecords.contains(firstRecord))
        XCTAssertTrue(subject.selectedRecords.contains(secondRecord))
    }

    func test_selectItem_withSameRecordTwice_keepsSingleEntry() {
        let subject = createSubject()
        let record = MockWebsiteDataRecord(displayName: "mozilla.org")

        subject.selectItem(record)
        subject.selectItem(record)

        XCTAssertEqual(subject.selectedRecords.count, 1)
        XCTAssertEqual(selectionChangedCallCount, 2)
    }

    func test_deselectItem_removesRecordFromSelection() {
        let subject = createSubject()
        let firstRecord = MockWebsiteDataRecord(displayName: "mozilla.org")
        let secondRecord = MockWebsiteDataRecord(displayName: "example.com")

        subject.selectItem(firstRecord)
        subject.selectItem(secondRecord)
        subject.deselectItem(firstRecord)

        XCTAssertEqual(subject.selectedRecords.count, 1)
        XCTAssertFalse(subject.selectedRecords.contains(firstRecord))
        XCTAssertTrue(subject.selectedRecords.contains(secondRecord))
    }

    func test_clearButtonTitle_withoutSelection_isClearAll() {
        let subject = createSubject()

        XCTAssertEqual(subject.clearButtonTitle, .SettingsClearAllWebsiteDataButton)
    }

    func test_clearButtonTitle_withSelection_countsSelectedRecords() {
        let subject = createSubject()

        subject.selectItem(MockWebsiteDataRecord(displayName: "mozilla.org"))
        XCTAssertEqual(subject.clearButtonTitle, String(format: .SettingsClearSelectedWebsiteDataButton, "1"))

        subject.selectItem(MockWebsiteDataRecord(displayName: "example.com"))
        XCTAssertEqual(subject.clearButtonTitle, String(format: .SettingsClearSelectedWebsiteDataButton, "2"))
    }

    func test_showMoreButtonPressed_setsDisplayAllStateWithoutNotifying() {
        let subject = createSubject()

        subject.showMoreButtonPressed()

        XCTAssertEqual(subject.state, .displayAll)
        XCTAssertEqual(selectionChangedCallCount, 0)
        XCTAssertEqual(viewModelChangedCallCount, 0)
    }

    // MARK: - Helpers
    private func createSubject() -> WebsiteDataManagementViewModel {
        let subject = WebsiteDataManagementViewModel()
        subject.onViewModelChanged = { [weak self] in self?.viewModelChangedCallCount += 1 }
        subject.onSelectionChanged = { [weak self] in self?.selectionChangedCallCount += 1 }
        trackForMemoryLeaks(subject)
        return subject
    }
}

private final class MockWebsiteDataRecord: WKWebsiteDataRecord {
    /// Instances are retained for the lifetime of the test run and never deallocated. `WKWebsiteDataRecord` embeds a
    /// C++ object that only WebKit constructs, so `super.init()` leaves it zeroed and `dealloc` crashes destroying it.
    private static var keepAlive = [MockWebsiteDataRecord]()

    private let mockDisplayName: String

    override var displayName: String { return mockDisplayName }

    init(displayName: String) {
        self.mockDisplayName = displayName
        super.init()
        Self.keepAlive.append(self)
    }
}
