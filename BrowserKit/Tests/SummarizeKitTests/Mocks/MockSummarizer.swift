// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

final class MockSummarizer: SummarizerProtocol, @unchecked Sendable {
    var modelName: SummarizerModel = .appleSummarizer

    /// If set, both `summarize` and `summarizeStreamed` will throw this error.
    var shouldThrowError: Error?
    /// The response content, split into chunks.
    /// Used as-is for `summarizeStreamed`, and joined with a whitespace for `summarize`.
    var shouldRespond: [String] = []

    init(shouldRespond: [String], shouldThrowError: Error?) {
        self.shouldRespond = shouldRespond
        self.shouldThrowError = shouldThrowError
    }

    func summarize(_ contentToSummarize: String) async throws -> String {
        if let error = shouldThrowError { throw error }
        return shouldRespond.joined(separator: " ")
    }

    func summarizeStreamed(_ contentToSummarize: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    if let error = shouldThrowError { throw error }

                    for chunk in shouldRespond {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
