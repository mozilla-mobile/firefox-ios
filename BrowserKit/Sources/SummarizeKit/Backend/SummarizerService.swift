// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// A service that handles checking if a web page can be summarized and
/// delegates summarization to the provided summarizer backend.
public final class SummarizerService {
    private let summarizer: SummarizerProtocol
    private let checker: SummarizationCheckerProtocol
    /// The maximum number of words allowed before rejecting summarization.
    /// Prevents model errors caused by exceeding token or context window limits.
    /// This is enforced by the injected JS, not the model itself.
    /// See UserScripts/MainFrame/AtDocumentStart/Summarizer.js for more context on how this is enforced.
    private let maxWords: Int

    public init(
        summarizer: SummarizerProtocol,
        checker: SummarizationCheckerProtocol = SummarizationChecker(),
        maxWords: Int
    ) {
        self.summarizer = summarizer
        self.checker = checker
        self.maxWords = maxWords
    }

    /// Generates a complete summary string from the given web view's page content.
    /// - Throws: `SummarizerError` if the content is unsuitable or summarization fails.
    /// - Returns: A fully summarized string for displaying.
    func summarize(from webView: WKWebView) async throws -> String {
        do {
            let text = try await extractSummarizableText(from: webView)
            return try await summarizer.summarize(text)
        } catch let summarizerError as SummarizerError {
            throw summarizerError
        } catch {
            throw SummarizerError.unknown(error)
        }
    }

    /// Streams a summary response from the web view's page content in chunks.
    /// Useful for providing progressive feedback while the model is still generating.
    /// - Returns: An `AsyncThrowingStream` emitting summary chunks as they arrive.
    /// - Note: Due to a Swift limitation (https://github.com/swiftlang/swift/issues/64165),
    ///   the stream must use a generic `Error` type. But all errors thrown from this method are `SummarizerError`.
    func summarizeStreamed(from webView: WKWebView) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let text = try await self.extractSummarizableText(from: webView)
                    let stream = summarizer.summarizeStreamed(text)

                    for try await chunk in stream {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                } catch let summarizerError as SummarizerError {
                    continuation.finish(throwing: summarizerError)
                } catch {
                    continuation.finish(throwing: SummarizerError.unknown(error))
                }
            }
        }
    }

    /// Helper that extracts summarizable text from the given web view.
    ///  `.check()` by design is async since we need to wait for the document to load before we start summarizing.
    /// - Throws: `SummarizerError` if the content is not suitable or parsing fails.
    /// - Returns: Cleaned text ready for summarization.
    private func extractSummarizableText(from webView: WKWebView) async throws -> String {
        let result = await checker.check(on: webView, maxWords: maxWords)
        guard result.canSummarize else { throw SummarizerError(reason: result.reason) }
        guard let text = result.textContent, !text.isEmpty else { throw SummarizerError.noContent }
        return text
    }
}
