// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class MockURLResponse: URLResponse, @unchecked Sendable {
    let filename: String

    override var suggestedFilename: String? {
        return filename
    }

    init(filename: String, url: URL) {
        self.filename = filename
        super.init(
            url: url,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
