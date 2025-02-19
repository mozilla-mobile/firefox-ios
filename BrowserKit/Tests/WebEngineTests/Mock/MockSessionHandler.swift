// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockSessionHandler: SessionHandler {
    var commitURLChangeCalled = 0
    var fetchMetadataCalled = 0
    var receivedErrorCalled = 0
    var savedError: NSError?
    var savedURL: URL?

    func commitURLChange() {
        commitURLChangeCalled += 1
    }

    func fetchMetadata(withURL url: URL) {
        savedURL = url
        fetchMetadataCalled += 1
    }

    func received(error: NSError, forURL url: URL) {
        savedError = error
        savedURL = url
        receivedErrorCalled += 1
    }
}
