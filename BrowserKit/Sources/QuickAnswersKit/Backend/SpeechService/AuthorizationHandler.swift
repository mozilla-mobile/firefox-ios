// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Speech

struct AuthorizationHandler: AuthorizeProvider {
    let audioSession: AudioSessionProvider

    init(audioSession: AudioSessionProvider = AVAudioSession()) {
        self.audioSession = audioSession
    }

    func requestMicrophonePermission() async throws {
        let isFirstTimeRequest = isMicrophonePermissionUndetermined()
        let isPermissionGranted = await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard !isPermissionGranted else { return }
        throw SpeechError.microphonePermissionDenied(isFirstTime: isFirstTimeRequest)
    }

    func requestSpeechPermission() async throws {
        let isFirstTimeRequest = isSpeechPermissionUndetermined()
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        let isPermissionGranted = status == .authorized
        guard !isPermissionGranted else { return }
        throw SpeechError.speechRecognitionPermissionDenied(isFirstTime: isFirstTimeRequest)
    }

    private func isMicrophonePermissionUndetermined() -> Bool {
        return audioSession.recordPermission == .undetermined
    }

    private func isSpeechPermissionUndetermined() -> Bool {
        return SFSpeechRecognizer.authorizationStatus() == .notDetermined
    }
}
