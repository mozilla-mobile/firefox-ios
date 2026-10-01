// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import SummarizeKit

class MockSummarizerService: SummarizerService {
    var summarizeCalled = 0
    var summarizeStreamedCalled = 0
    var mockChunchedResponse: [String] = []
    var mockError: Error?
    var closeCurrentStreamedSessionCalled = 0
    var delayStreamResultInSeconds: TimeInterval = 0

    func summarize(from webView: WKWebView) async throws -> String {
        summarizeCalled += 1
        return ""
    }

    func summarizeStreamed(from webView: WKWebView) -> AsyncThrowingStream<String, any Error> {
        summarizeStreamedCalled += 1
        return AsyncThrowingStream { continuation in
            Task {
                for chunck in mockChunchedResponse {
                    if #available(iOS 16.0, *) {
                        try await Task.sleep(for: .seconds(delayStreamResultInSeconds))
                    } else {
                        try await Task.sleep(nanoseconds: UInt64(delayStreamResultInSeconds) * 1_000_000_000)
                    }
                    continuation.yield(chunck)
                }
                if let mockError {
                    continuation.finish(throwing: mockError)
                } else {
                    continuation.finish()
                }
            }
        }
    }

    func closeCurrentStreamedSession() {
        closeCurrentStreamedSessionCalled += 1
    }
}
