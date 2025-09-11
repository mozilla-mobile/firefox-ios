// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

struct SummarizeState: Sendable {
    let isTosConsentAccepted: Bool
    let wasTosScreenShown: Bool
    let canSummarize: Bool

    init(
        isTosConsentAccepted: Bool,
        wasTosScreenShown: Bool = false,
        canSummarize: Bool = false,
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
        return SummarizeState(
            isTosConsentAccepted: isTosConsentAccepted ?? self.isTosConsentAccepted,
            wasTosScreenShown: wasTosScreenShown ?? self.wasTosScreenShown,
            canSummarize: canSummarize ?? self.canSummarize
        )
    }
}

@MainActor
public protocol SummarizeViewModel {
    func summarize(webView: WKWebView,
                   footNoteLabel: String,
                   onNewData: @escaping (Result<String, SummarizerError>) -> Void) async

    /// Free the lock on the summarization stream, and unlock the stream to send data the UI.
    func unblockSummarization()

    func closeSummarization()

    func setTosScreenShown()

    func setTosConsentAccepted()

    func logTosStatus()
}

public protocol SummarizeToSAcceptor: AnyObject {
    func acceptTosConsent()

    func denyTosConsent()
}

public final class DefaultSummarizeViewModel: SummarizeViewModel {
    struct Constansts {
        static let summaryDelay: CGFloat = 4.0
        static let minWordsAcceptedToShow = 2000
    }
    private let summarizerService: SummarizerService
    private var semaphoreContinuation: CheckedContinuation<Void, Never>?
    private var state: SummarizeState
    private let minWordsAcceptedToShow: Int
    private weak var tosAcceptor: SummarizeToSAcceptor?

    public init(
        summarizerService: SummarizerService,
        tosAcceptor: SummarizeToSAcceptor?,
        minWordsAcceptedToShow: Int? = nil,
        isTosAcceppted: Bool
    ) {
        self.summarizerService = summarizerService
        self.tosAcceptor = tosAcceptor
        self.minWordsAcceptedToShow = minWordsAcceptedToShow ?? Constansts.minWordsAcceptedToShow
        self.state = SummarizeState(isTosConsentAccepted: isTosAcceppted)
    }

    public func summarize(webView: WKWebView,
                          footNoteLabel: String,
                          onNewData: @escaping (Result<String, SummarizerError>) -> Void) async {
        guard state.isTosConsentAccepted else {
            onNewData(.failure(.tosConsentMissing))
            return
        }
        let startRevealingAt = Date().addingTimeInterval(Constansts.summaryDelay)
        var lastChunk = ""
        var revealed = false
        do {
            let stream = summarizerService.summarizeStreamed(from: webView)
            /// NOTE1: By design the APIs send aggregated tokens instead of individual chunks.
            /// We don't need to accumulate them.
            /// NOTE2: Wait for the specified delay before revealing the summary.
            /// This is done to provide a smoother user experience and avoid sudden changes.

            for try await aggregatedChunk in stream {
                lastChunk = aggregatedChunk
                guard Date() >= startRevealingAt || enoughWords(aggregatedChunk) else { continue }
                await waitForUnblockSummarization()
                revealed = true
                onNewData(.success(aggregatedChunk))
            }
            /// NOTE: Streaming especially from a request that was cached can be faster than `delay`.
            /// This is to make sure when that happens we show the summary immediately.
            if !revealed {
                await waitForUnblockSummarization()
                onNewData(.success(lastChunk))
            }

            let summaryWithNote = """
            \(lastChunk)

            ##### \(footNoteLabel)
            """
            onNewData(.success(summaryWithNote))
        } catch {
            guard let error = error as? SummarizerError else {
                onNewData(.failure(.unknown(error)))
                return
            }
            onNewData(.failure(error))
        }
    }

    private func enoughWords(_ text: String) -> Bool {
        return text.count > minWordsAcceptedToShow
    }

    private func waitForUnblockSummarization() async {
        await withCheckedContinuation { continuation in
            if self.state.canSummarize {
                continuation.resume()
            } else {
                self.semaphoreContinuation = continuation
            }
        }
    }

    public func unblockSummarization() {
        state = state.copy(canSummarize: true)
        semaphoreContinuation?.resume()
    }

    public func closeSummarization() {
        summarizerService.closeCurrentStreamedSession()
        semaphoreContinuation = nil
    }

    public func setTosScreenShown() {
        state = state.copy(wasTosScreenShown: true)
    }

    public func setTosConsentAccepted() {
        state = state.copy(isTosConsentAccepted: true)
        tosAcceptor?.acceptTosConsent()
    }

    public func logTosStatus() {
        guard !state.isTosConsentAccepted, state.wasTosScreenShown else { return }
        tosAcceptor?.denyTosConsent()
    }
}
