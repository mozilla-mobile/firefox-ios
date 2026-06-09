// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

/// Minimal mock route for TinyRouter tests.
/// Can simulate: returning a reply, returning nil (fall-through),
/// or throwing an error. Tracks how many times it was called.
final class MockRoute: TinyRoute, @unchecked Sendable {
    var calls: [URL] = []
    var reply: TinyHTTPReply?
    var error: Error?

    init(replyText: String) {
        self.reply = TinyHTTPReply(httpResponse: nil, body: Data(replyText.utf8))
    }

    init(reply: TinyHTTPReply? = nil, error: Error? = nil) {
        self.reply = reply
        self.error = error
    }

    func handle(url: URL, components: URLComponents) throws -> TinyHTTPReply? {
        calls.append(url)
        if let error { throw error }
        return reply
    }
}
