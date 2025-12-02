// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class DownloadsScreen {
    private let app: XCUIApplication
    private let sel: DownloadsSelectorsSet

    init(app: XCUIApplication, selectors: DownloadsSelectorsSet = DownloadsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var downloadsTable: XCUIElement { sel.DOWNLOADS_TABLE.element(in: app) }

    func assertNumberOfDownloadedItems(expectedCount: Int, file: StaticString = #filePath, line: UInt = #line) {
        let table = downloadsTable
        BaseTestCase().mozWaitForElementToExist(table)

        let actualCount = table.cells.count
        XCTAssertEqual(
            actualCount,
            expectedCount,
            "The number of items in the downloads table is not correct",
            file: file,
            line: line
        )
    }

    func assertDownloadedFileDetailsAreVisible(fileName: String, fileSize: String, timeout: TimeInterval = TIMEOUT) {
        let fileNameElement = sel.downloadedFileName(name: fileName).query(in: app).firstMatch
        let fileSizeElement = sel.downloadedFileSize(size: fileSize).query(in: app).firstMatch

        let requiredElements = [fileNameElement, fileSizeElement]
        BaseTestCase().waitForElementsToExist(requiredElements, timeout: timeout)
    }
}
