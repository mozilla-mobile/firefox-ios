// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import QuickAnswersKit

final class MockAuthorizer: AuthorizeProvider {
    let micAuthorized: Bool
    let speechAuthorized: Bool
    let micUndetermined: Bool
    let speechUndetermined: Bool

    init(
        micAuthorized: Bool = true,
        speechAuthorized: Bool = true,
        micUndetermined: Bool = false,
        speechUndetermined: Bool = false
    ) {
        self.micAuthorized = micAuthorized
        self.speechAuthorized = speechAuthorized
        self.micUndetermined = micUndetermined
        self.speechUndetermined = speechUndetermined
    }

    func requestMicrophonePermission() async throws {
        if !micAuthorized {
            throw SpeechError.microphonePermissionDenied(isFirstTime: micUndetermined)
        }
    }

    func requestSpeechPermission() async throws {
        if !speechAuthorized {
            throw SpeechError.speechRecognitionPermissionDenied(isFirstTime: speechUndetermined)
        }
    }
}
