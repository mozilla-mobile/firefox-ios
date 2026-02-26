// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Speech

/// A speech transcription engine backed by `AVAudioEngine` and `SFSpeechRecognizer`.
///
/// Responsible for:
/// - Managing permissions
/// - Capturing microphone audio
/// - Streaming transcription results
final actor SFSpeechRecognizerEngine: TranscriptionEngine {
    private let audioEngine: AudioEngineProvider
    private let audioSession: AudioSessionProvider

    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SpeechRecognizerProvider?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let authorizer: AuthorizeProvider

    init(
        locale: Locale = Locale.current,
        audioEngine: AudioEngineProvider = AVAudioEngine(),
        audioSession: AudioSessionProvider = AVAudioSession(),
        speechRecognizer: SpeechRecognizerProvider? = nil,
        authorizer: AuthorizeProvider? = nil
    ) {
        self.audioEngine = audioEngine
        self.audioSession = audioSession
        self.speechRecognizer = speechRecognizer ?? SFSpeechRecognizer(locale: locale)
        self.authorizer = authorizer ?? AuthorizationHandler(audioSession: audioSession)
    }

    func prepare() async throws {
        guard await isPermissionGranted() else {
            throw SpeechError.permissionDenied
        }
        try configureAudioSession()
    }

    // TODO: FXIOS-14878 - Refactor and extract similar audio code for both speech framework
    func start(continuation: AsyncThrowingStream<SpeechResult, any Error>.Continuation) async throws {
        // Setup for formatting raw samples
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest.requiresOnDeviceRecognition = true
        if #available(iOS 16.0, *) {
            recognitionRequest.addsPunctuation = true
        }
        self.request = recognitionRequest

        // Remove any previous input from microphone and capture audio
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        // Start recognizer task if available
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerNotAvailable
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            // TODO: FXIOS-14878 - To refactor when we create the bridge
            if let error {
                continuation.finish(throwing: error)
                return
            }
            guard let result else { return }
            // TODO: Should add safe guard for accessing this 0
            let confidence = result.bestTranscription.segments[0].confidence

            let chunk = result.bestTranscription.formattedString
            let transcriptComponents = chunk.components(
              separatedBy: .whitespacesAndNewlines
            )
            let formattedWords = transcriptComponents.filter { !$0.isEmpty }
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
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognitionTask?.finish()
    }

    private func isPermissionGranted() async -> Bool {
        let isMicAuthorized = await authorizer.isMicrophonePermissionAuthorized()
        let isSpeechAuthorized = await authorizer.isSpeechPermissionAuthorized()
        return isMicAuthorized && isSpeechAuthorized
    }

    // MARK: - Audio Related
    // TODO: FXIOS-14882 - Refactor audio portion to be in its own manager
    private func configureAudioSession() throws {
        try audioSession.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}
