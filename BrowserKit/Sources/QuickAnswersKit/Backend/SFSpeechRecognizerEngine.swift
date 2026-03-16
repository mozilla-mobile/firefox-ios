// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Speech

/// A speech transcription engine backed by `AVAudioEngine` and `SFSpeechRecognizer`.
///
/// Responsible for:
/// - Managing permissions
/// - Streaming transcription results
@MainActor
final class SFSpeechRecognizerEngine: TranscriptionEngine {
    private let audioManager: AudioManagerProtocol
    private let authorizer: AuthorizeProvider

    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SpeechRecognizerProvider?
    private var request: SFSpeechAudioBufferRecognitionRequest?

    init(
        locale: Locale = Locale.current,
        audioManager: AudioManagerProtocol,
        speechRecognizer: SpeechRecognizerProvider? = nil,
        authorizer: AuthorizeProvider
    ) {
        self.audioManager = audioManager
        self.speechRecognizer = speechRecognizer ?? SFSpeechRecognizer(locale: locale)
        self.authorizer = authorizer
    }

    func prepare() async throws {
        guard await isPermissionGranted() else {
            throw SpeechError.permissionDenied
        }
        try audioManager.configureAudioSession()
    }

    func start(continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation) async throws {
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.requiresOnDeviceRecognition = true
        self.request = recognitionRequest

        // Start capturing audio and append buffers to the recognition request
        try audioManager.startCapture(bufferSize: 4096) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        try audioManager.prepareAndStartEngine()

        // Start recognizer task if available
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let error {
                continuation.finish(throwing: error)
                return
            }
            guard let result else { return }
            let chunk = result.bestTranscription.formattedString
            let speechResult = SpeechResult(
                text: chunk,
                isFinal: result.isFinal
            )
            continuation.yield(speechResult)
            // TODO: FXIOS-14893 - Improve detection
            if result.isFinal || result.speechRecognitionMetadata != nil {
                continuation.finish()
            }
        }
    }

    func stop() {
        audioManager.stopEngine()
        request?.endAudio()
        recognitionTask?.finish()
    }

    private func isPermissionGranted() async -> Bool {
        let isMicAuthorized = await authorizer.isMicrophonePermissionAuthorized()
        let isSpeechAuthorized = await authorizer.isSpeechPermissionAuthorized()
        return isMicAuthorized && isSpeechAuthorized
    }
}
