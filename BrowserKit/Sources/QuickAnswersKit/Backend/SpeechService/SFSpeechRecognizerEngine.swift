// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Shared
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
        let isMicFirstTime = authorizer.isMicrophonePermissionUndetermined()
        let isSpeechFirstTime = authorizer.isSpeechPermissionUndetermined()

        let micGranted = await authorizer.isMicrophonePermissionAuthorized()
        if !micGranted {
            throw SpeechError.microphonePermissionDenied(isFirstTime: isMicFirstTime)
        }

        let speechGranted = await authorizer.isSpeechPermissionAuthorized()
        if !speechGranted {
            throw SpeechError.speechRecognitionPermissionDenied(isFirstTime: isSpeechFirstTime)
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
            let formattedWords = chunk
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }

            // `isFinal` is not reliable so we add extra checks
            // such as a confidence level as well as a cap of 50 words.
            // From manual testing, the confidence level is usually > 0.0 when user finishes speaking.
            let confidence = result.bestTranscription.segments[safe: 0]?.confidence ?? 0.0
            let additionalChecks = confidence > 0.0 || formattedWords.count >= 50
            let shouldFinish = result.isFinal || result.speechRecognitionMetadata != nil || additionalChecks

            let speechResult = SpeechResult(
                text: chunk,
                isFinal: shouldFinish
            )

            continuation.yield(speechResult)

            if shouldFinish {
                continuation.finish()
            }
        }
    }

    func stop() {
        audioManager.stopEngine()
        request?.endAudio()
        recognitionTask?.finish()
    }

}
