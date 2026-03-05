// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A concrete `VoiceSearchService` that records speech and emits transcription results
/// using an underlying `TranscriptionEngine`. As well as request search results from the transcription.
///
/// Engine selection
/// - iOS 26+ uses `SpeechAnalyzerEngine`.
/// - Earlier versions use `SFSpeechRecognizerEngine`.
///
/// - Important: This type is `@MainActor`. Calls are serialized on the main actor.

@MainActor
final class DefaultVoiceSearchService: VoiceSearchService {
    enum RecordingState: Equatable {
        case idle
        case recording
    }
    private let engine: TranscriptionEngine

    private var state: RecordingState = .idle
    private var recordingTask: Task<Void, Never>?
    private var continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation?

    /// Creates a new voice search service with a platform-appropriate transcription engine.
    init(engine: TranscriptionEngine? = nil) {
        self.engine = engine ?? Self.makeDefaultEngine()
    }

    func record() async throws -> AsyncThrowingStream<SpeechResult, Error> {
        try beginRecording()
        try await engine.prepare()

        return AsyncThrowingStream(bufferingPolicy: .unbounded) { [weak self] continuation in
            guard let self else {
                await self?.finishRecording()
                return
            }
            self.startRecordingTask(with: continuation)
            continuation.onTermination = { _ in
                self.finishRecording()
            }
        }
    }

    func stopRecording() async throws {
        try await engine.stop()
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
        with continuation: AsyncThrowingStream<SpeechResult, Error>.Continuation
    ) {
        recordingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await self.engine.start(continuation: continuation)
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }

    private func finishRecording() async {
        recordingTask = nil
        continuation = nil
        state = .idle
    }
    
    private static func makeDefaultEngine() -> TranscriptionEngine {
        if #available(iOS 26.0, *) {
            return SpeechAnalyzerEngine()
        } else {
            return SFSpeechRecognizerEngine()
        }
    }
}
