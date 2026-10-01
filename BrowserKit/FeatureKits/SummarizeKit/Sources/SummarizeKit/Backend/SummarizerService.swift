// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

public protocol SummarizerService {
    /// Generates a complete summary string from the given web view's page content.
    /// - Throws: `SummarizerError` if the content is unsuitable or summarization fails.
    /// - Returns: A fully summarized string for displaying.
    @MainActor
    func summarize(from webView: WKWebView) async throws -> String

    /// Streams a summary response from the web view's page content in chunks.
    /// Useful for providing progressive feedback while the model is still generating.
    /// - Returns: An `AsyncThrowingStream` emitting summary chunks as they arrive.
    /// - Note: Due to a Swift limitation (https://github.com/swiftlang/swift/issues/64165),
    ///   the stream must use a generic `Error` type. But all errors thrown from this method are `SummarizerError`.
    @MainActor
    func summarizeStreamed(from webView: WKWebView) -> AsyncThrowingStream<String, Error>

    func closeCurrentStreamedSession()
}

/// A default service that handles checking if a web page can be summarized and
/// delegates summarization to the provided summarizer backend.
public final class DefaultSummarizerService: SummarizerService {
    private let summarizer: SummarizerProtocol
    private let checker: SummarizationCheckerProtocol
    /// The maximum number of words allowed before rejecting summarization.
    /// Prevents model errors caused by exceeding token or context window limits.
    /// This is enforced by the injected JS, not the model itself.
    /// See UserScripts/MainFrame/AtDocumentStart/Summarizer.js for more context on how this is enforced.
    private let maxWords: Int
    private var streamContinuation: AsyncThrowingStream<String, Error>.Continuation?

    /// Lifecycle delegate for “started / completed / failed” callbacks.
    public weak var summarizerLifecycle: SummarizerServiceLifecycle?

    public init(
        summarizer: SummarizerProtocol,
        lifecycleDelegate: SummarizerServiceLifecycle?,
        checker: SummarizationCheckerProtocol = SummarizationChecker(),
        maxWords: Int
    ) {
        self.summarizer = summarizer
        self.summarizerLifecycle = lifecycleDelegate
        self.checker = checker
        self.maxWords = maxWords
    }

    public func summarize(from webView: WKWebView) async throws -> String {
        do {
            let text = try await extractSummarizableText(from: webView)
            summarizerLifecycle?.summarizerServiceDidStart(text)
            let summary = try await summarizer.summarize(text)
            summarizerLifecycle?.summarizerServiceDidComplete(summary, modelName: summarizer.modelName)
            return summary
        } catch let summarizerError as SummarizerError {
            summarizerLifecycle?.summarizerServiceDidFail(summarizerError, modelName: summarizer.modelName)
            throw summarizerError
        } catch {
            let summarizerError = SummarizerError.unknown(error)
            summarizerLifecycle?.summarizerServiceDidFail(summarizerError, modelName: summarizer.modelName)
            throw summarizerError
        }
    }

    public func summarizeStreamed(from webView: WKWebView) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            streamContinuation = continuation
            Task { @MainActor in
                do {
                    let text = try await self.extractSummarizableText(from: webView)
                    summarizerLifecycle?.summarizerServiceDidStart(text)
                    let stream = try await summarizer.summarizeStreamed(text)
                    var summary = ""

                    for try await chunk in stream {
                        summary = chunk
                        continuation.yield(chunk)
                    }
                    summarizerLifecycle?.summarizerServiceDidComplete(summary, modelName: summarizer.modelName)
                    continuation.finish()
                } catch let summarizerError as SummarizerError {
                    summarizerLifecycle?.summarizerServiceDidFail(summarizerError, modelName: summarizer.modelName)
                    continuation.finish(throwing: summarizerError)
                } catch {
                    let summarizerError = SummarizerError.unknown(error)
                    summarizerLifecycle?.summarizerServiceDidFail(summarizerError, modelName: summarizer.modelName)
                    continuation.finish(throwing: summarizerError)
                }
            }
        }
    }

    public func closeCurrentStreamedSession() {
        streamContinuation?.finish(throwing: CancellationError())
        streamContinuation = nil
    }

    /// Helper that extracts summarizable text from the given web view.
    ///  `.check()` by design is async since we need to wait for the document to load before we start summarizing.
    /// - Throws: `SummarizerError` if the content is not suitable or parsing fails.
    /// - Returns: Cleaned text ready for summarization.
    @MainActor
    private func extractSummarizableText(from webView: WKWebView) async throws -> String {
        let result = await checker.check(on: webView, maxWords: maxWords)
        guard result.canSummarize else { throw SummarizerError(reason: result.reason) }
        guard let text = result.textContent, !text.isEmpty else { throw SummarizerError.noContent }
        return text
    }
}
