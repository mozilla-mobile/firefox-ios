// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockMetadataFetcherHelper: MetadataFetcherHelper {
    weak var delegate: MetadataFetcherDelegate?
    var fetchFromSessionCalled = 0
    var savedURL: URL?

    func fetch(fromSession session: WKEngineSession, url: URL) {
        fetchFromSessionCalled += 1
        savedURL = url
    }
}
