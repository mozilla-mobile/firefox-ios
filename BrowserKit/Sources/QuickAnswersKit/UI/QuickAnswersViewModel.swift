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
    let feature: QuickAnswersFeature
    var onStateChange: ((State) -> Void)?

    /// The user-facing name of the model backing the request.
    var modelDisplayName: String {
        return feature.model.displayName
    }
    private var model: QuickAnswersModel {
        return feature.model
    }

    var isOptInRequired: Bool {
        return !store.isOptInCompleted
    }

    /// Whether a question asked after an answer follows up on it, rather than being a new one.
    var supportsFollowUpQuestions: Bool {
        return feature.supportsFollowUpQuestions
    }

    /// Whether the opt-in is required and shown as a sheet over the browser rather than inline.
    var isOptInSheetRequired: Bool {
        return isOptInRequired && feature.isOptInRedesignEnabled
    }

    init(
        prefs: Prefs,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher?,
        makeService: (Prefs, QuickAnswersConfigFetcher) throws -> QuickAnswersService = { prefs, configFetcher in
            try DefaultQuickAnswersService(configFetcher: configFetcher, prefs: prefs)
        }
    ) {
        let configFetcher = configFetcher ?? DefaultQuickAnswersConfigFetcher(
            feature: QuickAnswersFeature(model: .exa, isOptInRedesignEnabled: false)
        )
        self.telemetry = telemetry
        self.store = Store(prefs: prefs)
        self.feature = configFetcher.feature
        do {
            self.service = try makeService(prefs, configFetcher)
        } catch {
            self.service = nil
        }
        telemetry.quickAnswersRequested(model: model)
    }

    /// Entry point for the flow: shows the opt-in screen until the user has consented,
    /// otherwise begins recording.
    func startFlow() {
        guard store.isOptInCompleted else {
            onStateChange?(.showOptIn)
            return
        }
        startRecordingVoice(isFollowUp: false)
    }

    /// Records the user's consent, persists the completed opt-in and starts the recording flow.
    func completeOptIn() {
        telemetry.consentShown(agreed: true)
        store.setOptInCompleted()
        startFlow()
    }

    /// Starts recording a question asked after a previous answer, tagging its telemetry as a follow up.
    func startFollowUp() {
        startRecordingVoice(isFollowUp: true)
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

    private func startRecordingVoice(isFollowUp: Bool) {
        guard let service else {
            let error = SpeechError.serviceNotInitialized
            recordRecordingFailure(error, isFollowUp: isFollowUp)
            onStateChange?(.speechResult(.empty(), error))
            return
        }
        searchResultTask?.cancel()
        searchResultTask = nil
        recordVoiceTask = Task { [weak self] in
            try? await self?.recordVoiceTask(service: service, isFollowUp: isFollowUp)
        }
    }

    private func recordVoiceTask(service: QuickAnswersService, isFollowUp: Bool) async throws {
        do {
            let stream = try await service.record()
            onStateChange?(.recordingStarted)
            telemetry.recordingStarted(isFollowUp: isFollowUp)
            for try await result in stream {
                try Task.checkCancellation()
                onStateChange?(.speechResult(result, nil))

                guard result.isFinal else { continue }

                telemetry.recordingCompleted(outcome: true, errorType: nil, isFollowUp: isFollowUp)
                try? await service.stopRecording()
                await searchVoiceResult(result, service: service, isFollowUp: isFollowUp)

                break
            }
        } catch {
            try? await service.stopRecording()
            let error = (error as? SpeechError) ?? SpeechError.unknown(error.telemetryDescription)
            recordRecordingFailure(error, isFollowUp: isFollowUp)
            onStateChange?(.speechResult(.empty(), error))
        }
    }

    private func recordRecordingFailure(_ error: SpeechError, isFollowUp: Bool) {
        switch error {
        case .microphonePermissionDenied:
            telemetry.permissionDenied(permission: .microphone, isFollowUp: isFollowUp)
        case .speechRecognitionPermissionDenied:
            telemetry.permissionDenied(permission: .speechRecognition, isFollowUp: isFollowUp)
        default:
            telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel, isFollowUp: isFollowUp)
        }
    }

    private func stopRecordingVoice() async throws {
        recordVoiceTask?.cancel()
        recordVoiceTask = nil
        try await service?.stopRecording()
    }

    private func searchVoiceResult(_ result: SpeechResult, service: QuickAnswersService, isFollowUp: Bool) async {
        onStateChange?(.loadingSearchResult)
        telemetry.resultsStarted(isFollowUp: isFollowUp)
        let searchResult = await service.search(text: result.text)
        switch searchResult {
        case .success(let result):
            telemetry.resultsCompleted(outcome: true, errorType: nil, model: model, isFollowUp: isFollowUp)
            onStateChange?(.showSearchResult(result, nil))
        case .failure(let error):
            telemetry.resultsCompleted(
                outcome: false,
                errorType: error.telemetryLabel,
                model: model,
                isFollowUp: isFollowUp
            )
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }

    func recordCitationTapped() {
        telemetry.citationTapped()
    }
}
