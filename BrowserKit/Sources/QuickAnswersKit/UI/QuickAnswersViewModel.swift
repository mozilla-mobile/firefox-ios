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
    private let model: QuickAnswersModel
    private let feedbackPlayer: RecordingFeedbackPlayer
    private var recordVoiceTask: Task<Void, Never>?
    private var searchResultTask: Task<Void, Never>?
    var onStateChange: ((State) -> Void)?

    /// The user-facing name of the model backing the request.
    var modelDisplayName: String {
        return model.displayName
    }

    var isOptInRequired: Bool {
        return !store.isOptInCompleted
    }

    init(
        prefs: Prefs,
        telemetry: QuickAnswersTelemetry,
        configFetcher: QuickAnswersConfigFetcher = DefaultQuickAnswersConfigFetcher(model: .exa),
        feedbackPlayer: RecordingFeedbackPlayer = DefaultRecordingFeedbackPlayer(),
        makeService: (Prefs, QuickAnswersConfigFetcher) throws -> QuickAnswersService = { prefs, configFetcher in
            try DefaultQuickAnswersService(configFetcher: configFetcher, prefs: prefs)
        }
    ) {
        self.telemetry = telemetry
        self.store = Store(prefs: prefs)
        self.model = configFetcher.model
        self.feedbackPlayer = feedbackPlayer
        do {
            self.service = try makeService(prefs, configFetcher)
        } catch {
            self.service = nil
        }
        telemetry.quickAnswersRequested(model: self.model)
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

    /// Starts a new recording so the user can ask a follow up question. The exchanges already made are
    /// kept by the service and sent along with the new question.
    func startFollowUp() {
        startRecordingVoice()
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
            recordRecordingFailure(error)
            onStateChange?(.speechResult(.empty(), error))
            return
        }
        searchResultTask?.cancel()
        searchResultTask = nil
        recordVoiceTask = Task { [weak self] in
            try? await self?.recordVoiceTask(service: service)
        }
    }

    private func recordVoiceTask(service: QuickAnswersService) async throws {
        telemetry.recordingStarted()
        do {
            let stream = try await service.record()
            await feedbackPlayer.playRecordingStart()
            onStateChange?(.recordingStarted)
            for try await result in stream {
                try Task.checkCancellation()
                onStateChange?(.speechResult(result, nil))

                guard result.isFinal else { continue }

                telemetry.recordingCompleted(outcome: true, errorType: nil)
                try? await service.stopRecording()
                feedbackPlayer.playRecordingEnd()
                await searchVoiceResult(result, service: service)

                break
            }
        } catch {
            try? await service.stopRecording()
            let error = (error as? SpeechError) ?? SpeechError.unknown(error.telemetryDescription)
            recordRecordingFailure(error)
            onStateChange?(.speechResult(.empty(), error))
        }
    }

    private func recordRecordingFailure(_ error: SpeechError) {
        switch error {
        case .microphonePermissionDenied:
            telemetry.permissionDenied(permission: .microphone)
        case .speechRecognitionPermissionDenied:
            telemetry.permissionDenied(permission: .speechRecognition)
        default:
            telemetry.recordingCompleted(outcome: false, errorType: error.telemetryLabel)
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
            telemetry.resultsCompleted(outcome: true, errorType: nil, model: model)
            onStateChange?(.showSearchResult(result, nil))
        case .failure(let error):
            telemetry.resultsCompleted(outcome: false, errorType: error.telemetryLabel, model: model)
            onStateChange?(.showSearchResult(.empty(), error))
        }
    }

    func recordCitationTapped() {
        telemetry.citationTapped()
    }
}
