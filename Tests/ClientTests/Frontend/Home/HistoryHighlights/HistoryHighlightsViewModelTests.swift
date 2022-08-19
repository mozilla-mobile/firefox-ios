// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

class HistoryHighlightsViewModelTests: XCTestCase {

    private var sut: HistoryHighlightsViewModel!
    private var profile: MockProfile!
    private var tabManager: MockTabManager!
    private var dataAdaptor: MockHistoryHighlightsDataAdaptor!
    private var delegate: MockHomepageDataModelDelegate!
    private var telemetry: MockTelemetryWrapper!
    private var urlBar: MockURLBarView!

    override func setUp() {
        super.setUp()

        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        tabManager = MockTabManager()
        dataAdaptor = MockHistoryHighlightsDataAdaptor()
        delegate = MockHomepageDataModelDelegate()
        telemetry = MockTelemetryWrapper()
        urlBar = MockURLBarView()
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        tabManager = nil
        dataAdaptor = nil
        sut = nil
        delegate = nil
        telemetry = nil
        urlBar = nil
    }

    func testLoadNewDataIsEnabled() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "mozilla")]

        sut.didLoadNewData()

        XCTAssertEqual(sut.getItemDetailsAt(index: 0)?.displayTitle, "mozilla")
        XCTAssertEqual(delegate.reloadViewCallCount, 1)
    }

    func testLoadNewDataIsNotEnabled() {
        setupSubject(isPrivate: true)
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "mozilla")]

        sut.didLoadNewData()

        XCTAssertEqual(sut.getItemDetailsAt(index: 0)?.displayTitle, "mozilla")
        XCTAssertEqual(delegate.reloadViewCallCount, 0)
    }

    func testOneColumns() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three")]

        sut.didLoadNewData()

        XCTAssertEqual(sut.numberOfColumns, 1)
        XCTAssertEqual(sut.numberOfRows, 3)
    }

    func testTwoColumns() {
        setupSubject()
        dataAdaptor.mockHistoryItems = [getItemWithTitle(title: "one"),
                                        getItemWithTitle(title: "two"),
                                        getItemWithTitle(title: "three"),
                                        getItemWithTitle(title: "four")]

        sut.didLoadNewData()

        XCTAssertEqual(sut.numberOfColumns, 2)
        XCTAssertEqual(sut.numberOfRows, 3)
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

        sut.didLoadNewData()

        XCTAssertEqual(sut.numberOfColumns, 3)
        XCTAssertEqual(sut.numberOfRows, 3)
    }

    func testRecordSectionHasShown() {
        setupSubject()

        sut.recordSectionHasShown()

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.view))
        XCTAssertTrue(telemetry.recordedObjects.contains(.historyImpressions))
    }

    func testRecordSectionHasShownOnlyOnce() {
        setupSubject()

        sut.recordSectionHasShown()
        sut.recordSectionHasShown()

        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.view))
        XCTAssertTrue(telemetry.recordedObjects.contains(.historyImpressions))
    }

    func testSwitchToWhileInOverlayMode() {
        setupSubject()
        urlBar.inOverlayMode = true

        sut.switchTo(getItemWithTitle(title: "item"))

        XCTAssertEqual(urlBar.leaveOverlayModeCallCount, 1)
        XCTAssertEqual(telemetry.recordEventCallCount, 1)
        XCTAssertTrue(telemetry.recordedCategories.contains(.action))
        XCTAssertTrue(telemetry.recordedMethods.contains(.tap))
        XCTAssertTrue(telemetry.recordedObjects.contains(.firefoxHomepage))
    }

    // MARK: - Helper methods

    private func setupSubject(isPrivate: Bool = false) {
        sut = HistoryHighlightsViewModel(
            with: profile,
            isPrivate: isPrivate,
            tabManager: tabManager,
            urlBar: urlBar,
            historyHighlightsDataAdaptor: dataAdaptor,
            dispatchQueue: MockDispatchQueue(),
            telemetry: telemetry)
        sut.delegate = delegate
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
