// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
@testable import Client
import MozillaAppServices

class HistoryHighlightsViewModelTests: XCTestCase {
    private var subject: HistoryHighlightsViewModel!
    private var profile: MockProfile!
    private var dataAdaptor: MockHistoryHighlightsDataAdaptor!
    private var delegate: MockHomepageDataModelDelegate!
    private var telemetry: MockTelemetryWrapper!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        dataAdaptor = MockHistoryHighlightsDataAdaptor()
        delegate = MockHomepageDataModelDelegate()
        telemetry = MockTelemetryWrapper()
    }

    override func tearDown() {
        profile = nil
        dataAdaptor = nil
        subject = nil
        delegate = nil
        telemetry = nil
        super.tearDown()
    }

    func testLoadNewDataIsEnabled() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "mozilla")]

        subject.didLoadNewData()

        XCTAssertEqual(subject.getItemDetailsAt(index: 0)?.displayTitle, "mozilla")
        XCTAssertEqual(delegate.reloadViewCallCount, 0)
    }

    func testLoadNewDataIsNotEnabled() {
        setupSubject(isPrivate: true)
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "mozilla")]

        subject.didLoadNewData()

        XCTAssertEqual(subject.getItemDetailsAt(index: 0)?.displayTitle, "mozilla")
        XCTAssertEqual(delegate.reloadViewCallCount, 0)
    }

    func testOneColumns() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three")]

        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfColumns, 1)
        XCTAssertEqual(subject.numberOfRows, 3)
    }

    func testTwoColumns() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four")]

        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfColumns, 2)
        XCTAssertEqual(subject.numberOfRows, 3)
    }

    func testThreeColumns() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four"),
                                        getItemWithTitle(title: "five"),
                                        getItemWithTitle(title: "six"),
                                        getItemWithTitle(title: "seven")]

        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfColumns, 3)
        XCTAssertEqual(subject.numberOfRows, 3)
    }

    func testRecordSectionHasShown() {
        setupSubject()

        subject.recordSectionHasShown()

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.view))
        XCTAssertTrue(telemetry.recordedObjects.contains(.historyImpressions))
    }

    func testRecordSectionHasShownOnlyOnce() {
        setupSubject()

        subject.recordSectionHasShown()
        subject.recordSectionHasShown()

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.view))
        XCTAssertTrue(telemetry.recordedObjects.contains(.historyImpressions))
    }

    func testSwitchToWhileInOverlayMode() {
        setupSubject()

        subject.switchTo(getItemWithTitle(title: "item"))

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.tap))
        XCTAssertTrue(telemetry.recordedObjects.contains(.firefoxHomepage))
    }

    func testDelete() {
        setupSubject()
        subject.delete(getItemWithTitle(title: "to-delete"))

        XCTAssertEqual(dataAdaptor.deleteCallCount, 1)
    }

    func testNumberOfItemsInSection1Column() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two")]
        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfItemsInSection(), 2)
    }

    func testNumberOfItemsInSection2Column() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four")]
        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfItemsInSection(), 6)
    }

    func testNumberOfItemsInSection3Column() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four"),
                                        getItemWithTitle(title: "five"),
                                        getItemWithTitle(title: "six"),
                                        getItemWithTitle(title: "seven")]
        subject.didLoadNewData()

        XCTAssertEqual(subject.numberOfItemsInSection(), 9)
    }

    func testConfigureFillerCell() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four")]
        subject.didLoadNewData()
        let cell = subject.configure(
            HistoryHighlightsCell(),
            at: IndexPath(row: 5, section: 0)
        ) as? HistoryHighlightsCell

        XCTAssertNotNil(cell)
        XCTAssertTrue(cell!.isFillerCell)
    }

    func testConfigureIndividualCell() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one")]
        subject.didLoadNewData()
        let cell = subject.configure(
            HistoryHighlightsCell(),
            at: IndexPath(row: 0, section: 0)
        ) as? HistoryHighlightsCell

        XCTAssertNotNil(cell)
        XCTAssertFalse(cell!.isFillerCell)
    }

    func testConfigureGroupCell() {
        setupSubject()
        let item = ASGroup(searchTerm: "",
                           groupedItems: [getItemWithTitle(title: "one"), getItemWithTitle(title: "two")],
                           timestamp: 0)

        dataAdaptor.mockHistoryItems = [item]
        subject.didLoadNewData()
        let cell = subject.configure(
            HistoryHighlightsCell(),
            at: IndexPath(row: 0, section: 0)
        ) as? HistoryHighlightsCell

        XCTAssertNotNil(cell)
        XCTAssertFalse(cell!.isFillerCell)
        XCTAssertEqual(cell!.itemDescription.text,
                       String.localizedStringWithFormat(.FirefoxHomepage.Common.PagesCount, 2))
    }

    func testDidSelectItem() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one")]
        subject.didLoadNewData()
        subject.didSelectItem(at: IndexPath(row: 0, section: 0),
                              homePanelDelegate: nil,
                              libraryPanelDelegate: nil)

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.tap))
        XCTAssertTrue(telemetry.recordedObjects.contains(.firefoxHomepage))
    }

    // MARK: - Helper methods

    private func setupSubject(isPrivate: Bool = false) {
        subject = HistoryHighlightsViewModel(
            with: profile,
            isPrivate: isPrivate,
            theme: LightTheme(),
            historyHighlightsDataAdaptor: dataAdaptor,
            dispatchQueue: MockDispatchQueue(),
            telemetry: telemetry,
            wallpaperManager: WallpaperManager())
        subject.delegate = delegate
    }

    private func getItemWithTitle(title: String) -> HighlightItem {
        return HistoryHighlight(
            score: 0,
            placeId: 0,
            url: "",
            title: title,
            previewImageUrl: "")
    }
}
