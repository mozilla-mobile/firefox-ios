// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

@MainActor
final class QuickAnswersViewModel {
    enum State: Equatable {
        case initializationFailed
        case recordVoice(SpeechResult, SpeechError?)
        case loadingSearchResult
        case showSearchResult(SearchResult, ResultsServiceError?)
    }

    private let service: QuickAnswersService?
    private let telemetry: QuickAnswersTelemetry
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
        do {
            self.service = try makeService(prefs, configFetcher)
        } catch {
            // TODO: FXIOS-15570 - Possibly add telemetry to capture service failing
            self.service = nil
        }
        telemetry.quickAnswersRequested()
    }

    func startRecordingVoice() {
        guard let service else {
            onStateChange?(.initializationFailed)
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
        telemetry.recordingStarted()
        do {
            let stream = try await service.record()
            for try await result in stream {
                try Task.checkCancellation()
                recentSpeechResult = result
                onStateChange?(.recordVoice(result, nil))
                guard result.isFinal else { continue }
                telemetry.recordingCompleted(outcome: true, errorType: nil)
                await searchVoiceResult(result, service: service)
                break
            }
        } catch {
            let error = (error as? SpeechError) ?? SpeechError.unknown(error.localizedDescription)
            telemetry.recordingCompleted(outcome: false, errorType: error.localizedDescription)
            onStateChange?(.recordVoice(.empty(), error))
        }
    }

    // TODO: FXIOS-14880 - Update view model
    func stopRecordingVoice() async throws {
        guard let service else {
            onStateChange?(.initializationFailed)
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

    private func searchVoiceResult(_ result: SpeechResult, service: QuickAnswersService) async {
        onStateChange?(.loadingSearchResult)
        telemetry.resultsStarted()
        let searchResult = await service.search(text: result.text)
        switch searchResult {
        case .success(let result):
            telemetry.resultsCompleted(outcome: true, errorType: nil)
            onStateChange?(.showSearchResult(result, nil))
        case .failure(let error):
            telemetry.resultsCompleted(outcome: false, errorType: error.localizedDescription)
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }

    func recordConsentShown(_ agreed: Bool) {
        telemetry.consentShown(agreed: agreed)
    }

    func recordClosed() {
        telemetry.closed()
    }
}
