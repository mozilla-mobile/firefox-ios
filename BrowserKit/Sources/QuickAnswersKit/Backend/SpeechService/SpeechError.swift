// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum SpeechError: Error, Equatable {
    case alreadyRecording
    case failedToAllocateBuffer
    case microphonePermissionDenied(isFirstTime: Bool)
    case noAudioFormat
    case noInputContinuation
    case recognizerNotAvailable
    case speechRecognitionPermissionDenied(isFirstTime: Bool)
    case unableToSupportLocale
    case unknown(String)
}
