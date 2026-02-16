// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Speech

// MARK: - Abstractions
// TODO: FXIOS-14878 - May need to refactor after integrating new speech framework as well
extension AVAudioEngine: AudioEngineProvider { }
extension AVAudioSession: AudioSessionProvider { }
extension SFSpeechRecognizer: SpeechRecognizerProvider { }

protocol AudioEngineProvider: Sendable {
    var inputNode: AVAudioInputNode { get }
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
