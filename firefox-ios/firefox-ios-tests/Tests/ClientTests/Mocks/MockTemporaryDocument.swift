// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockTemporaryDocument: TemporaryDocument {
    var fileURL: URL
    var getURLCalled = 0
    var getDownloadedURLCalled = 0

    init(withFileURL fileURL: URL) {
        self.fileURL = fileURL
    }

    func getURL(completionHandler: @escaping ((URL?) -> Void)) {
        getURLCalled += 1
        completionHandler(fileURL)
    }

    func getDownloadedURL() async -> URL? {
        getDownloadedURLCalled += 1
        return fileURL
    }
}
