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
        /// Debug only: asks the view to collect the question by hand, for the simulator where the microphone
        /// can't be used.
        case requestsTypedQuestion
    }

    private let service: QuickAnswersService?
    private let telemetry: QuickAnswersTelemetry
    private let store: Store
    private let usesTypedQuestion: Bool
    private var recordVoiceTask: Task<Void, Never>?
    private var searchResultTask: Task<Void, Never>?
    var onStateChange: ((State) -> Void)?

    /// The user-facing name of the model backing the request.
    let modelDisplayName: String

    /// - Parameter usesTypedQuestion: replaces the recording step with a question the user types, for the debug
    /// builds running on the simulator where the microphone isn't usable.
    init(
        prefs: Prefs,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher = DefaultQuickAnswersConfigFetcher(model: .exa),
        usesTypedQuestion: Bool = false,
        makeService: (Prefs, QuickAnswersConfigFetcher) throws -> QuickAnswersService = { prefs, configFetcher in
            try DefaultQuickAnswersService(configFetcher: configFetcher, prefs: prefs)
        }
    ) {
        self.telemetry = telemetry
        self.store = Store(prefs: prefs)
        self.usesTypedQuestion = usesTypedQuestion
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
        guard !usesTypedQuestion else {
            onStateChange?(.requestsTypedQuestion)
            return
        }

        recordVoiceTask = Task { [weak self] in
            try? await self?.recordVoiceTask(service: service)
        }
    }

    /// Debug counterpart of the recording flow: searches a question the user typed instead of one transcribed
    /// from the microphone.
    func search(typedQuestion: String) {
        guard let service else { return }
        let text = typedQuestion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let result = SpeechResult(text: text, isFinal: true)
        onStateChange?(.speechResult(result, nil))
        searchResultTask = Task { [weak self] in
            await self?.searchVoiceResult(result, service: service)
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

    private func searchVoiceResult(_ result: SpeechResult, service: QuickAnswersService) async {
        onStateChange?(.loadingSearchResult)
        telemetry.resultsStarted()
        let searchResult = await service.search(text: result.text)
        switch searchResult {
        case .success(let result):
            telemetry.resultsCompleted(outcome: true, errorType: nil)
            onStateChange?(.showSearchResult(result, nil))
        case .failure(let error):
            telemetry.resultsCompleted(outcome: false, errorType: error.telemetryLabel)
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }

    func recordCitationTapped() {
        telemetry.citationTapped()
    }
}
