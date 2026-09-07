// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

@MainActor
final class QuickAnswersViewModel {
    enum State: Equatable {
        case showOptIn
        case recordingStarted
        case speechResult(SpeechResult, SpeechError?)
        case loadingSearchResult
        case showSearchResult(SearchResult, ResultsServiceError?)
    }

    private struct Constants {
        /// Chunks arrive faster than the answer label can cross dissolve, so updates are throttled.
        static let searchResultThrottleInterval: TimeInterval = 0.2
    }

    private let service: QuickAnswersService?
    private let telemetry: QuickAnswersTelemetry
    private let store: Store
    private let searchResultThrottleInterval: TimeInterval
    private var recordVoiceTask: Task<Void, Never>?
    private var searchResultTask: Task<Void, Never>?
    /// Non-nil while the throttle is closed, i.e. while a result was emitted less than
    /// `searchResultThrottleInterval` ago.
    private var searchResultThrottleTask: Task<Void, Never>?
    /// The latest result withheld by the throttle. Only the last one is kept, since every chunk
    /// carries the whole answer accumulated so far.
    private var throttledSearchResult: SearchResult?
    var onStateChange: ((State) -> Void)?

    /// The user-facing name of the model backing the request.
    let modelDisplayName: String

    init(
        prefs: Prefs,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher = DefaultQuickAnswersConfigFetcher(model: .exa),
        searchResultThrottleInterval: TimeInterval = Constants.searchResultThrottleInterval,
        makeService: (Prefs, QuickAnswersConfigFetcher) throws -> QuickAnswersService = { prefs, configFetcher in
            try DefaultQuickAnswersService(configFetcher: configFetcher, prefs: prefs)
        }
    ) {
        self.telemetry = telemetry
        self.store = Store(prefs: prefs)
        self.searchResultThrottleInterval = searchResultThrottleInterval
        self.modelDisplayName = configFetcher.model.displayName
        do {
            self.service = try makeService(prefs, configFetcher)
        } catch {
            self.service = nil
        }
        telemetry.quickAnswersRequested()
    }

    /// Entry point for the flow: shows the opt-in screen until the user has consented,
    /// otherwise begins recording.
    func startFlow() {
        guard store.isOptInCompleted else {
            onStateChange?(.showOptIn)
            return
        }
        startRecordingVoice()
    }

    /// Records the user's consent, persists the completed opt-in and starts the recording flow.
    func completeOptIn() {
        telemetry.consentShown(agreed: true)
        store.setOptInCompleted()
        startFlow()
    }

    /// Tears down the flow when the view is being dismissed, recording the relevant telemetry.
    func dismiss() {
        // if the opt-in is not completed at time of dismissal stopRecording triggers permission request, thus
        // we'd show a permission alert on dismissal which we don't want.
        // TODO: FXIOS-16224 - add isRecording parameter to transcription engine to perform clean up only when needed
        if store.isOptInCompleted {
            // TODO: FXIOS-14880 - Possibly investigate a better way to call this via view model
            Task { [weak self] in
                try? await self?.stopRecordingVoice()
            }
        } else {
            telemetry.consentShown(agreed: false)
        }
        telemetry.closed()
    }

    private func startRecordingVoice() {
        guard let service else {
            let error = SpeechError.serviceNotInitialized
            telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel)
            onStateChange?(.speechResult(.empty(), error))
            return
        }
        searchResultTask?.cancel()
        searchResultTask = nil
        cancelSearchResultThrottle()
        recordVoiceTask = Task { [weak self] in
            try? await self?.recordVoiceTask(service: service)
        }
    }

    private func recordVoiceTask(service: QuickAnswersService) async throws {
        onStateChange?(.recordingStarted)
        telemetry.recordingStarted()
        do {
            let stream = try await service.record()
            for try await result in stream {
                try Task.checkCancellation()
                onStateChange?(.speechResult(result, nil))

                guard result.isFinal else { continue }

                telemetry.recordingCompleted(outcome: true, errorType: nil)
                try? await service.stopRecording()
                await searchVoiceResult(result, service: service)

                break
            }
        } catch {
            try? await service.stopRecording()
            let error = (error as? SpeechError) ?? SpeechError.unknown(error.localizedDescription)
            telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel)
            onStateChange?(.speechResult(.empty(), error))
        }
    }

    private func stopRecordingVoice() async throws {
        recordVoiceTask?.cancel()
        recordVoiceTask = nil
        try await service?.stopRecording()
    }

    /// Consumes the streamed search results so the view can grow the answer as it arrives, throttled
    /// to one update per `searchResultThrottleInterval`. Telemetry is recorded once, when the stream
    /// completes.
    private func searchVoiceResult(_ result: SpeechResult, service: QuickAnswersService) async {
        onStateChange?(.loadingSearchResult)
        telemetry.resultsStarted()
        do {
            for try await searchResult in await service.search(text: result.text) {
                try Task.checkCancellation()
                emitThrottled(searchResult)
            }
            flushThrottledSearchResult()
            telemetry.resultsCompleted(outcome: true, errorType: nil)
        } catch is CancellationError {
            cancelSearchResultThrottle()
            return
        } catch {
            cancelSearchResultThrottle()
            let error = (error as? ResultsServiceError) ?? ResultsServiceError.unknown(error.localizedDescription)
            telemetry.resultsCompleted(outcome: false, errorType: error.telemetryLabel)
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }

    /// Emits `result` right away when the throttle is open, then closes it for
    /// `searchResultThrottleInterval`. Results arriving while it is closed replace one another, and
    /// the last of them is emitted as soon as the interval elapses.
    private func emitThrottled(_ result: SearchResult) {
        guard searchResultThrottleTask == nil else {
            throttledSearchResult = result
            return
        }
        onStateChange?(.showSearchResult(result, nil))
        let interval = searchResultThrottleInterval
        searchResultThrottleTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(interval * Double(NSEC_PER_SEC)))
            self?.openSearchResultThrottle()
        }
    }

    /// Reopens the throttle, emitting whatever was withheld while it was closed.
    private func openSearchResultThrottle() {
        searchResultThrottleTask = nil
        guard let throttledSearchResult else { return }
        self.throttledSearchResult = nil
        emitThrottled(throttledSearchResult)
    }

    /// Emits the withheld result without waiting for the interval to elapse, for when the stream has
    /// no more chunks to send.
    private func flushThrottledSearchResult() {
        searchResultThrottleTask?.cancel()
        searchResultThrottleTask = nil
        guard let throttledSearchResult else { return }
        self.throttledSearchResult = nil
        onStateChange?(.showSearchResult(throttledSearchResult, nil))
    }

    /// Drops the throttle state without emitting, for when the flow is interrupted.
    private func cancelSearchResultThrottle() {
        searchResultThrottleTask?.cancel()
        searchResultThrottleTask = nil
        throttledSearchResult = nil
    }

    func recordCitationTapped() {
        telemetry.citationTapped()
    }
}
