// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import LLMKit
import Shared

/// A concrete `QuickAnswersService` that records speech and emits transcription results
/// using an underlying `TranscriptionEngine`. As well as request results from the transcription via `ResultsService` flow.
///
/// Engine selection
/// - iOS 26+ uses `SpeechAnalyzerEngine`.
/// - Earlier versions use `SFSpeechRecognizerEngine`.
@MainActor
final class DefaultQuickAnswersService: QuickAnswersService {
    enum RecordingState: Equatable {
        case idle
        case recording
    }

    private let engine: TranscriptionEngine
    private let resultsService: ResultsService
    private var state: RecordingState = .idle
    private var recordingTask: Task<Void, Error>?
    private var continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation?

    /// Creates a new service with a platform-appropriate transcription engine and results service.
    init(
        engine: TranscriptionEngine? = nil,
        resultsServiceFactory: ResultsServiceFactory = DefaultResultsServiceFactory(
            config: QuickAnswersConfig(),
            liteLLMCreator: LiteLLMCreator()
        ),
        prefs: Prefs
    ) throws {
        self.engine = engine ?? Self.makeDefaultEngine()
        let config = QuickAnswersConfig()
        guard let resultsService = resultsServiceFactory.make(prefs: prefs, config: config) else {
            throw ResultsServiceError.unableToCreateService
        }
        self.resultsService = resultsService
    }

    // MARK: Speech Service
    /// Starts a new voice recording session and returns a stream of transcription results.
    /// - Ensures no other recording session is active.
    /// - Prepares the underlying transcription engine.
    /// - Launches an internal task that feeds results into the returned stream.
    func record() async throws -> AsyncThrowingStream<SpeechResult, Error> {
        try beginRecording()
        try await engine.prepare()

        return AsyncThrowingStream { [weak self] continuation in
            self?.startRecordingTask(with: continuation)
        }
    }

    /// Stops the current recording session by cancelling any recording task, stopping the underlying engine,
    /// and resets the service to the `.idle` state.
    func stopRecording() async throws {
        cleanUp()
        try await engine.stop()
        state = .idle
    }

    // MARK: Results Service
    // TODO: FXIOS-15197 - Implement parsing logic based on response format and update Search Result
    // also remove search terminology while we are here

    /// Performs a search for the given transcription using the ResultsService.
    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        do {
            let result = try await resultsService.fetchResults(for: text)
            return .success(result)
        } catch {
            // TODO: FXIOS-15198 Handle errors appropriately
            return .failure(.unknown)
        }
    }

    // MARK: Private Methods
    private func beginRecording() throws {
        guard state == .idle else { throw SpeechError.alreadyRecording }
        state = .recording
        cleanUp()
    }

    private func cleanUp() {
        recordingTask?.cancel()
        recordingTask = nil
        continuation = nil
    }

    private func startRecordingTask(
        with continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation
    ) {
        recordingTask?.cancel()
        recordingTask = Task { [weak self] in
            do {
                try Task.checkCancellation()
                try await self?.engine.start(continuation: continuation)
            } catch is CancellationError {
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    private static func makeDefaultEngine() -> TranscriptionEngine {
        let audioManager = AudioManager()
        let authorizer = AuthorizationHandler()

        if #available(iOS 26.0, *) {
            return SpeechAnalyzerEngine(
                audioManager: audioManager,
                authorizer: authorizer
            )
        } else {
            return SFSpeechRecognizerEngine(
                audioManager: audioManager,
                authorizer: authorizer
            )
        }
    }
}
