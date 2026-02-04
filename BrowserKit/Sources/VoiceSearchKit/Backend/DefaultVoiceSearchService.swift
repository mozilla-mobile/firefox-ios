// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import AVFoundation
import Speech

actor DefaultVoiceSearchService: VoiceSearchService {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    private var isRecording = false

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    nonisolated func recordVoice() -> AsyncThrowingStream<SpeechResult, any Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await self.startRecording(continuation: continuation)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func startRecording(
        continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation
    ) async throws {
        guard !isRecording else {
            throw SpeechError.unknown
        }

        try await requestPermissions()

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.unknown
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Setup audio engine and recognition
        let audioEngine = AVAudioEngine()
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        self.audioEngine = audioEngine
        self.recognitionRequest = recognitionRequest

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let speechResult = SpeechResult(
                    text: result.bestTranscription.formattedString,
                    isFinal: result.isFinal || result.speechRecognitionMetadata != nil
                )
                continuation.yield(speechResult)

                if result.isFinal || result.speechRecognitionMetadata != nil {
                    continuation.finish()
                }
            }

            if let error = error {
                continuation.finish(throwing: error)
            }
        }

        isRecording = true
    }

    private func requestPermissions() async throws {
        try await withCheckedThrowingContinuation { continuation in
            if #available(iOS 17, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    granted ? continuation.resume() : continuation.resume(throwing: SpeechError.unknown)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    granted ? continuation.resume() : continuation.resume(throwing: SpeechError.unknown)
                }
            }
        }

        try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                status == .authorized ? continuation.resume() : continuation.resume(throwing: SpeechError.unknown)
            }
        }
    }

    nonisolated func stopRecordingVoice() {
        Task {
            await cleanup()
        }
    }

    private func cleanup() {
        guard isRecording else { return }

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
    }

    func search(text: String) async -> Result<SearchResult, SearchResultError> {
        return await MockVoiceSearchService().search(text: text)
    }
}
