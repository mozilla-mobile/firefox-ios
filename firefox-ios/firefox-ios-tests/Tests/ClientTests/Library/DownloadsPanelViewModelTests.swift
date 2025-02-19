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
        fileFetcher = nil
        super.tearDown()
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

    func testIsFirstSection_ForToday() {
        let todayResults: [Date: Int] = [Date().noon: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(0))
    }

    func testIsFirstSection_ForYesterday() {
        let todayResults: [Date: Int] = [Date.yesterday: 2,
                                         Date().lastMonth: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(1))
    }

    func testIsFirstSection_ForLastWeek() {
        let todayResults: [Date: Int] = [Date().lastWeek: 4,
                                         Date().lastMonth: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(2))
    }

    func testIsFirstSection_ForLastMonth() {
        let todayResults: [Date: Int] = [Date().lastMonth: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertTrue(viewModel.isFirstSection(3))
    }

    func testFalseIsFirstSection_WithEarlierResults() {
        let todayResults: [Date: Int] = [Date().noon: 2,
                                         Date.yesterday: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertFalse(viewModel.isFirstSection(1))
        XCTAssertTrue(viewModel.isFirstSection(0))
    }

    func testHeaderTitle_ForToday() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 0), .LibraryPanel.Sections.Today)
    }

    func testHeaderTitle_ForYesterday() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 1), .LibraryPanel.Sections.Yesterday)
    }

    func testHeaderTitle_ForLastWeek() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 2), .LibraryPanel.Sections.LastWeek)
    }

    func testHeaderTitle_ForLastMonth() {
        let viewModel = createSubject()
        XCTAssertEqual(viewModel.headerTitle(for: 3), .LibraryPanel.Sections.LastMonth)
    }

    func testHeaderTitle_ForInvalidSection() {
        let viewModel = createSubject()
        XCTAssertNil(viewModel.headerTitle(for: 4))
    }

    func testGetDownloadFile_ForTodaySecondFile() {
        let todayResults: [Date: Int] = [Date().noon: 4,
                                         Date.yesterday: 2,
                                         Date().lastWeek: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        guard let downloadFile = viewModel.downloadedFileForIndexPath(IndexPath(row: 1, section: 0)) else {
            XCTFail("Expected to found the second file from today section")
            return
        }

        XCTAssertEqual(downloadFile.path.absoluteString, "https://test1.file.com")
        XCTAssertTrue(downloadFile.lastModified.isToday())
    }

    func testGetNumberOfItems_ForToday() {
        let todayResults: [Date: Int] = [Date().noon: 3]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 0), 3)
    }

    func testGetNumberOfItems_ForYesterday() {
        let todayResults: [Date: Int] = [Date.yesterday: 2]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 1), 2)
    }

    func testGetNumberOfItems_ForLastWeek() {
        let todayResults: [Date: Int] = [getDate(dayOffset: -6): 5]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 2), 5)
    }

    func testGetNumberOfItems_ForLastMonth() {
        let todayResults: [Date: Int] = [getDate(dayOffset: -25): 4]
        let viewModel = createSubject(resultsPerSection: todayResults)
        viewModel.reloadData()

        XCTAssertEqual(viewModel.getNumberOfItems(for: 3), 4)
    }

    func testDeleteItem_ForToday() {
        let todayResults: [Date: Int] = [Date().noon: 4]
        let viewModel = createSubject(resultsPerSection: todayResults)
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
