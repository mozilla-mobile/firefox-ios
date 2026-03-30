// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Speech

// MARK: - Abstractions
// TODO: FXIOS-14878 - May need to refactor after integrating new speech framework as well
extension AVAudioEngine: AudioEngineProvider {
    var audioInputNode: AudioInputNodeProvider {
        inputNode
    }
}
extension AVAudioSession: AudioSessionProvider { }
extension SFSpeechRecognizer: SpeechRecognizerProvider { }
extension AVAudioInputNode: AudioInputNodeProvider { }

protocol AudioInputNodeProvider: Sendable {
    func outputFormat(forBus bus: AVAudioNodeBus) -> AVAudioFormat
    func installTap(
        onBus bus: AVAudioNodeBus,
        bufferSize: AVAudioFrameCount,
        format: AVAudioFormat?,
        block: @escaping @Sendable AVAudioNodeTapBlock
    )
    func removeTap(onBus bus: AVAudioNodeBus)
}

protocol AudioEngineProvider: Sendable {
    var audioInputNode: AudioInputNodeProvider { get }
    func prepare()
    func start() throws
    func stop()
}

protocol AudioSessionProvider: Sendable {
    func requestRecordPermission(_ response: @escaping @Sendable (Bool) -> Void)
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws
    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws
}

protocol AudioManagerProtocol {
    func configureAudioSession() throws
    func prepareAndStartEngine() throws
    func stopEngine()

    /// Starts capturing microphone audio without format conversion.
    func startCapture(
        bufferSize: AVAudioFrameCount,
        handler: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void
    ) throws

    /// Starts capturing microphone audio with optional format conversion.
    /// If the microphone's native format differs from the target format, audio buffers
    /// are automatically converted before being passed to the handler.
    func startCapture(
        targetFormat: AVAudioFormat,
        bufferSize: AVAudioFrameCount,
        handler: @escaping @Sendable (AVAudioPCMBuffer) -> Void
    ) throws
}

protocol SpeechRecognizerProvider: Sendable {
    var isAvailable: Bool { get }
    func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask
}

protocol AuthorizeProvider: Sendable {
    func isMicrophonePermissionAuthorized() async -> Bool
    func isSpeechPermissionAuthorized() async -> Bool
}
