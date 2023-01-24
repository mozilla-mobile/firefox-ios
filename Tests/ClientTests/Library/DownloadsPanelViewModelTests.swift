// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

final class DownloadsPanelViewModelTests: XCTestCase {
    private var fileFetcher: DownloadFileFetcher!

    override func setUp() {
        super.setUp()
        fileFetcher = MockDownloadFileFetcher()
    }

    override func tearDown() {
        super.tearDown()
        fileFetcher = nil
    }

    func testExample() {
        let viewModel = createSubject()
        viewModel.reloadData()

        XCTAssertTrue(viewModel.hasDownloadedFiles)
    }

    private func createSubject() -> DownloadsPanelViewModel {
        let viewModel = DownloadsPanelViewModel(fileFetcher: fileFetcher)
        trackForMemoryLeaks(viewModel)
        return viewModel
    }
}

class MockDownloadFileFetcher: DownloadFileFetcher {
    func fetchData() -> [DownloadedFile] {
        var files = [DownloadedFile]()

        for _ in 0..<3 {
            files.append(createDownloadedFile(for: .yesterday))
        }

        return files
    }

    private func createDownloadedFile(for date: Date) -> DownloadedFile {
        let downloadedFile = DownloadedFile(path: (URL(string: "https://test.file.com")!),
                                            size: 20,
                                            lastModified: date)
        return downloadedFile
    }
}
