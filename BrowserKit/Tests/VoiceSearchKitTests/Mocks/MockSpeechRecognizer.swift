// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Speech

@testable import VoiceSearchKit

final class MockSpeechRecognizer: SpeechRecognizerProvider, @unchecked Sendable {
    var isAvailable = true
    private(set) var recognitionTaskCallCount = 0

    func recognitionTask(
        with request: SFSpeechRecognitionRequest,
        resultHandler: @escaping (SFSpeechRecognitionResult?, Error?) -> Void
    ) -> SFSpeechRecognitionTask {
        recognitionTaskCallCount += 1
        return SFSpeechRecognitionTask()
    }
}
