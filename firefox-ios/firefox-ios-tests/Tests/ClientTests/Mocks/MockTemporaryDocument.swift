// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockTemporaryDocument: TemporaryDocument {
    var sourceURL: URL? {
        return request?.url
    }
    var fileURL: URL
    var filename = ""
    var isDownloading = false
    var downloadCalled = 0
    var downloadAsyncCalled = 0
    var canDownloadCalled = 0
    var cancelDownloadCalled = 0
    var pauseDownloadCalled = 0
    var resumeDownloadCalled = 0
    var request: URLRequest?

    init(withFileURL fileURL: URL,
         request: URLRequest? = nil) {
        self.fileURL = fileURL
        self.request = request
    }

    init() {
        fileURL = URL(fileURLWithPath: "test")
    }

    func canDownload(request: URLRequest) -> Bool {
        canDownloadCalled += 1
        return request.url != self.request?.url
    }

    func download(_ completion: @escaping (URL?) -> Void) {
        downloadCalled += 1
        completion(fileURL)
    }

    func download() async -> URL? {
        downloadAsyncCalled += 1
        return fileURL
    }

    func cancelDownload() {
        cancelDownloadCalled += 1
    }

    func pauseDownload() {
        pauseDownloadCalled += 1
    }

    func resumeDownload() {
        resumeDownloadCalled += 1
    }
}
