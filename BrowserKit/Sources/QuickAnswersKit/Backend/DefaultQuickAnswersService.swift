// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A concrete `QuickAnswersService` that records speech and emits transcription results
/// using an underlying `TranscriptionEngine`. As well as request search results from the transcription.
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
    private var state: RecordingState = .idle
    private var recordingTask: Task<Void, Error>?
    private var continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation?

    /// Creates a new service with a platform-appropriate transcription engine.
    init(engine: TranscriptionEngine? = nil) {
        self.engine = engine ?? Self.makeDefaultEngine()
    }

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

    /// Performs a search for the given text.
    ///
    /// - Note: Currently returns an empty success result. See `FXIOS-14949`.
    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        // TODO: FXIOS-14949 - Add search results from search service
        return .success(SearchResult.empty())
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
