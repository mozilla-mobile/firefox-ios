// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Speech

final class AuthorizationHandler: AuthorizeProvider {
    let audioSession: AudioSessionProvider
    init(audioSession: AudioSessionProvider) {
        self.audioSession = audioSession
    }
    func isMicrophonePermissionAuthorized() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func isSpeechPermissionAuthorized() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        return status == .authorized
    }
}
