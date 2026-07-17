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
    case serviceNotInitialized
    case speechRecognitionPermissionDenied(isFirstTime: Bool)
    case unableToSupportLocale
    case unknown(String)

    var telemetryLabel: String {
        switch self {
        case .alreadyRecording: return "already_recording"
        case .failedToAllocateBuffer: return "failed_to_allocate_buffer"
        case .microphonePermissionDenied: return "microphone_permission_denied"
        case .noAudioFormat: return "no_audio_format"
        case .noInputContinuation: return "no_input_continuation"
        case .recognizerNotAvailable: return "recognizer_not_available"
        case .serviceNotInitialized: return "service_not_initialized"
        case .speechRecognitionPermissionDenied: return "speech_recognition_permission_denied"
        case .unableToSupportLocale: return "unable_to_support_locale"
        case .unknown: return "unknown"
        }
    }
}
