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

    private let service: QuickAnswersService?
    private let telemetry: QuickAnswersTelemetry
    private let store: Store
    private var recordVoiceTask: Task<Void, Never>?
    private var searchResultTask: Task<Void, Never>?
    private var recentSpeechResult: SpeechResult?
    var onStateChange: ((State) -> Void)?

    init(
        prefs: Prefs,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher = DefaultQuickAnswersConfigFetcher(model: .exa),
        makeService: (Prefs, QuickAnswersConfigFetcher) throws -> QuickAnswersService = { prefs, configFetcher in
            try DefaultQuickAnswersService(configFetcher: configFetcher, prefs: prefs)
        }
    ) {
        self.telemetry = telemetry
        self.store = Store(prefs: prefs)
        do {
            self.service = try makeService(prefs, configFetcher)
        } catch {
            // TODO: FXIOS-15570 - Possibly add telemetry to capture service failing
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
        // if the optin is not completed at time of dismissal stopRecording triggers permission request, thus
        // we'd show a permission alert on dismissal which we don't want.
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
            emitServiceNotInitialized()
            return
        }
        searchResultTask?.cancel()
        searchResultTask = nil
        recordVoiceTask = Task { [weak self] in
            try? await self?.recordVoiceTask(service: service)
        }
    }

    // TODO: FXIOS-14880 - Update view model
    private func recordVoiceTask(service: QuickAnswersService) async throws {
        onStateChange?(.recordingStarted)
        telemetry.recordingStarted()
        do {
            let stream = try await service.record()
            for try await result in stream {
                try Task.checkCancellation()
                recentSpeechResult = result
                onStateChange?(.speechResult(result, nil))
                guard result.isFinal else { continue }
                telemetry.recordingCompleted(outcome: true, errorType: nil)
                await searchVoiceResult(result, service: service)
                break
            }
        } catch {
            let error = (error as? SpeechError) ?? SpeechError.unknown(error.localizedDescription)
            telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel)
            onStateChange?(.speechResult(.empty(), error))
        }
    }

    // TODO: FXIOS-14880 - Update view model
    private func stopRecordingVoice() async throws {
        guard let service else {
            emitServiceNotInitialized()
            return
        }

        recordVoiceTask?.cancel()
        recordVoiceTask = nil
        try await service.stopRecording()
        guard let recentSpeechResult, searchResultTask == nil else { return }
        searchResultTask = Task { [weak self] in
            do {
                try Task.checkCancellation()
                await self?.searchVoiceResult(recentSpeechResult, service: service)
            } catch {
                return
            }
        }
    }
    
    private func emitServiceNotInitialized() {
        let error = SpeechError.serviceNotInitialized
        telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel)
        onStateChange?(.speechResult(.empty(), error))
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
