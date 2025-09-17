// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

@MainActor
public protocol SummarizeViewModel {
    func summarize(webView: WKWebView,
                   footNoteLabel: String,
                   dateProvider: DateProvider,
                   onNewData: @escaping (Result<String, SummarizerError>) -> Void)

    /// Free the lock on the summarization stream, and unlock the stream to send data to the UI.
    func unblockSummarization()

    func closeSummarization()

    func setConsentScreenShown()

    func setConsentAccepted()

    func logConsentStatus()
}

public protocol SummarizeTermOfServiceAcceptor: AnyObject {
    func acceptConsent()

    func denyConsent()
}

public protocol DateProvider {
    func currentDate() -> Date
}

struct DefaultDateProvider: DateProvider {
    func currentDate() -> Date {
        return Date.now
    }
}

public final class DefaultSummarizeViewModel: SummarizeViewModel {
    struct Configuration: Sendable {
        let isTosConsentAccepted: Bool
        let wasTosScreenShown: Bool
        let canSummarize: Bool

        init(
            isTosConsentAccepted: Bool,
            wasTosScreenShown: Bool = false,
            canSummarize: Bool = false
        ) {
            self.isTosConsentAccepted = isTosConsentAccepted
            self.canSummarize = canSummarize
            self.wasTosScreenShown = wasTosScreenShown
        }

        func copy(
            isTosConsentAccepted: Bool? = nil,
            wasTosScreenShown: Bool? = nil,
            canSummarize: Bool? = nil
        ) -> Self {
            return Configuration(
                isTosConsentAccepted: isTosConsentAccepted ?? self.isTosConsentAccepted,
                wasTosScreenShown: wasTosScreenShown ?? self.wasTosScreenShown,
                canSummarize: canSummarize ?? self.canSummarize
            )
        }
    }
    struct Constants {
        static let summaryDelay: CGFloat = 4.0
        static let minWordsAcceptedToShow = 2000
    }
    private let summarizerService: SummarizerService
    private var semaphoreContinuation: CheckedContinuation<Void, Never>?
    private var configuration: Configuration
    private let minWordsAcceptedToShow: Int
    private let minDelayToShowSummary: TimeInterval
    private var summarizeTask: Task<Void, Never>?
    private weak var tosAcceptor: SummarizeTermOfServiceAcceptor?

    public init(
        summarizerService: SummarizerService,
        tosAcceptor: SummarizeTermOfServiceAcceptor?,
        minWordsAcceptedToShow: Int? = nil,
        minDelayToShowSummary: TimeInterval? = nil,
        isTosAcceppted: Bool
    ) {
        self.summarizerService = summarizerService
        self.tosAcceptor = tosAcceptor
        self.minDelayToShowSummary = minDelayToShowSummary ?? Constants.summaryDelay
        self.minWordsAcceptedToShow = minWordsAcceptedToShow ?? Constants.minWordsAcceptedToShow
        self.configuration = Configuration(isTosConsentAccepted: isTosAcceppted)
    }

    public func summarize(webView: WKWebView,
                          footNoteLabel: String,
                          dateProvider: DateProvider,
                          onNewData: @escaping (Result<String, SummarizerError>) -> Void) {
        summarizeTask?.cancel()
        summarizeTask = Task {
            guard configuration.isTosConsentAccepted else {
                await waitForUnblockSummarization()
                onNewData(.failure(.tosConsentMissing))
                return
            }
            let startRevealingAt = dateProvider.currentDate().addingTimeInterval(minDelayToShowSummary)
            var lastChunk = ""
            var revealed = false
            do {
                let stream = summarizerService.summarizeStreamed(from: webView)
                // NOTE1: By design the APIs send aggregated tokens instead of individual chunks.
                // We don't need to accumulate them.
                // NOTE2: Wait for the specified delay before revealing the summary.
                // This is done to provide a smoother user experience and avoid sudden changes.
                for try await aggregatedChunk in stream {
                    lastChunk = aggregatedChunk
                    guard dateProvider.currentDate() >= startRevealingAt || enoughWords(aggregatedChunk) else { continue }
                    await waitForUnblockSummarization()
                    revealed = true
                    try Task.checkCancellation()
                    onNewData(.success(aggregatedChunk))
                }
                // NOTE: Streaming especially from a request that was cached can be faster than `delay`.
                // This is to make sure when that happens we show the summary immediately.
                if !revealed {
                    await waitForUnblockSummarization()
                    try Task.checkCancellation()
                    onNewData(.success(lastChunk))
                }
                let summaryWithNote = """
                \(lastChunk)

                ##### \(footNoteLabel)
                """
                try Task.checkCancellation()
                onNewData(.success(summaryWithNote))
            } catch {
                handleSummarizationError(error: error, onError: onNewData)
            }
        }
    }

    private func handleSummarizationError(error: Error,
                                          onError: @escaping (Result<String, SummarizerError>) -> Void) {
        if error is CancellationError {
            return
        }
        guard let error = error as? SummarizerError else {
            onError(.failure(.unknown(error)))
            return
        }
        onError(.failure(error))
    }

    private func enoughWords(_ text: String) -> Bool {
        return text.count > minWordsAcceptedToShow
    }

    private func waitForUnblockSummarization() async {
        await withCheckedContinuation { continuation in
            if self.configuration.canSummarize {
                continuation.resume()
            } else {
                self.semaphoreContinuation = continuation
            }
        }
    }

    public func unblockSummarization() {
        configuration = configuration.copy(canSummarize: true)
        semaphoreContinuation?.resume()
    }

    public func closeSummarization() {
        summarizerService.closeCurrentStreamedSession()
        semaphoreContinuation = nil
    }

    public func setConsentScreenShown() {
        configuration = configuration.copy(wasTosScreenShown: true)
    }

    public func setConsentAccepted() {
        configuration = configuration.copy(isTosConsentAccepted: true)
        tosAcceptor?.acceptConsent()
    }

    public func logConsentStatus() {
        guard !configuration.isTosConsentAccepted, configuration.wasTosScreenShown else { return }
        tosAcceptor?.denyConsent()
    }
}
