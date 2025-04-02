// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

class DownloadsPanelViewModelTests: XCTestCase {
    private var fileFetcher: MockDownloadFileFetcher!

    override func setUp() {
        super.setUp()
        fileFetcher = MockDownloadFileFetcher()
    }

    override func tearDown() {
        super.tearDown()
        fileFetcher = nil
    }

    func testReloadData_WithResults() {
        let todayResults: [Date: Int] = [Date.yesterday: 3]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.hasDownloadedFiles)
    }

    func testReloadData_WithoutResults() {
        let viewModel = createSubject()
        viewModel.reloadData()

        XCTAssertFalse(viewModel.hasDownloadedFiles)
    }

    // Test that "Last 24 hours" is the first section
    func testIsFirstSection_ForLastTwentyFourHours() {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        let twelveHoursAgoResults: [Date: Int] = [twelveHoursAgo: 1]
        let viewModel = createSubject(resultsPerSection: twelveHoursAgoResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(0))
    }

    // Test that "Last 7 days" is the first section
    func testIsFirstSection_ForLastSevenDays() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let threeDaysAgoResults: [Date: Int] = [threeDaysAgo: 2,
                                         Date().lastMonth: 2]
        let viewModel = createSubject(resultsPerSection: threeDaysAgoResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(1))
    }

    // Test that "Last 4 weeks" is the first section
    func testIsFirstSection_ForLastFourWeeks() {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let twoWeeksAgoResults: [Date: Int] = [twoWeeksAgo: 4,
                                         Date().lastMonth: 2]
        let viewModel = createSubject(resultsPerSection: twoWeeksAgoResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(2))
    }

    func testFalseIsFirstSection_WithEarlierResults() {
        let todayResults: [Date: Int] = [Date().noon: 2,
                                         Date.yesterday: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertFalse(viewModel.isFirstSection(1))
        XCTAssertTrue(viewModel.isFirstSection(0))
    }

    func testHeaderTitle_ForLastTwentyFourHours() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 0), .LibraryPanel.Sections.LastTwentyFourHours)
    }

    func testHeaderTitle_ForLastSevenDays() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 1), .LibraryPanel.Sections.LastSevenDays)
    }

    func testHeaderTitle_ForLastFourWeeks() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 2), .LibraryPanel.Sections.LastFourWeeks)
    }

    func testHeaderTitle_ForInvalidSection() {
        let viewModel = createSubject()
        XCTAssertNil(viewModel.headerTitle(for: 4))
    }

    func testGetDownloadFile_ForLastTwentyFourHoursSecondFile() {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        let twelveHoursAgoResults: [Date: Int] = [twelveHoursAgo: 4,
                                         Date.yesterday: 2,
                                         Date().lastWeek: 2]
        let viewModel = createSubject(resultsPerSection: twelveHoursAgoResults)
        viewModel.reloadData()

        guard let downloadFile = viewModel.downloadedFileForIndexPath(IndexPath(row: 1, section: 0)) else {
            XCTFail("Expected to found the second file from today section")
            return
        }

        XCTAssertEqual(downloadFile.path.absoluteString, "https://test1.file.com")
        XCTAssertTrue(downloadFile.lastModified.isWithinLastTwentyFourHours())
    }

    func testGetNumberOfItems_ForLastTwentyFourHours() {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        let twelveHoursAgoResults: [Date: Int] = [twelveHoursAgo: 3]
        let viewModel = createSubject(resultsPerSection: twelveHoursAgoResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 0), 3)
    }

    func testGetNumberOfItems_ForLastSevenDays() {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let threeDaysAgoResults: [Date: Int] = [threeDaysAgo: 2]
        let viewModel = createSubject(resultsPerSection: threeDaysAgoResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 1), 2)
    }

    func testGetNumberOfItems_ForLastFourWeeks() {
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let twoWeeksAgoResults: [Date: Int] = [twoWeeksAgo: 5]
        let viewModel = createSubject(resultsPerSection: twoWeeksAgoResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 2), 5)
    }

    func testGetNumberOfItems_ForOlder() {
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()
        let twoMonthsAgoResults: [Date: Int] = [twoMonthsAgo: 4]
        let viewModel = createSubject(resultsPerSection: twoMonthsAgoResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 3), 4)
    }

    func testDeleteItem_ForLastTwentyFourHours() {
        let twelveHoursAgo = Calendar.current.date(byAdding: .hour, value: -12, to: Date()) ?? Date()
        let twelveHoursAgoResults: [Date: Int] = [twelveHoursAgo: 4]
        let viewModel = createSubject(resultsPerSection: twelveHoursAgoResults)
        viewModel.reloadData()
        let deletedFile = DownloadedFile(path: URL(string: "https://test0.file.com")!,
                                         size: 20,
                                         lastModified: Date().noon)
        viewModel.removeDownloadedFile(deletedFile)
        XCTAssertEqual(viewModel.getNumberOfItems(for: 0), 3)
    }

    // MARK: - Private

    private func createSubject(resultsPerSection: [Date: Int] = [Date: Int]()) -> DownloadsPanelViewModel {
        let viewModel = DownloadsPanelViewModel(fileFetcher: fileFetcher)
        fileFetcher.resultsPerSection = resultsPerSection
        trackForMemoryLeaks(viewModel)
        return viewModel
    }

    private func getDate(dayOffset: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let today = calendar.date(from: components)!
        return calendar.date(byAdding: .day, value: dayOffset, to: today)!
    }
}

class MockDownloadFileFetcher: DownloadFileFetcher {
    var resultsPerSection = [Date: Int]()

    func fetchData() -> [DownloadedFile] {
        var files = [DownloadedFile]()

        for section in resultsPerSection {
            for file in 0..<section.value {
                files.append(createDownloadedFile(for: section.key, index: file))
            }
        }

        return files
    }

    private func createDownloadedFile(for date: Date, index: Int) -> DownloadedFile {
        let url = URL(string: "https://test\(index).file.com")!
        let downloadedFile = DownloadedFile(path: url,
                                            size: 20,
                                            lastModified: date)
        return downloadedFile
    }
}

extension Date {
    public func isWithinLastTwentyFourHours(comparisonDate: Date = Date()) -> Bool {
        return (comparisonDate.lastTwentyFourHours ... comparisonDate).contains(self)
    }
}
