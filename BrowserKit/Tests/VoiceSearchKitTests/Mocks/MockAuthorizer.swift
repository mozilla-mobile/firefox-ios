// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
@testable import VoiceSearchKit

final class MockAuthorizer: AuthorizeProvider {
    let micAuthorized: Bool
    let speechAuthorized: Bool

    init(micAuthorized: Bool = true, speechAuthorized: Bool = true) {
        self.micAuthorized = micAuthorized
        self.speechAuthorized = speechAuthorized
    }

    func isMicrophonePermissionAuthorized() async -> Bool {
        micAuthorized
    }

    func isSpeechPermissionAuthorized() async -> Bool {
        speechAuthorized
    }
}
