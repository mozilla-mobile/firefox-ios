// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import FoundationModels

/// Error types for summarization flows, mapping underlying model errors to user‑friendly cases.
/// The UI layer will rely on userMessage to display appropriate messages.
enum SummarizerError: Error, LocalizedError, Sendable {
    case tooLong
    case rateLimited
    case busy
    case safetyBlocked
    case unsupportedLanguage
    case invalidResponse
    case cancelled
    case unknown(Error)

    var errorDescription: String? { userMessage }

    // TODO(FXIOS-12934): Localize these strings
    var userMessage: String {
        switch self {
        case .tooLong: return ""
        case .rateLimited: return ""
        case .busy: return ""
        case .safetyBlocked: return ""
        case .unsupportedLanguage: return ""
        case .cancelled: return ""
        case .invalidResponse: return ""
        case .unknown: return ""
        }
    }

    /// Initialize from a specific generation error type. 
    @available(iOS 26, *)
    init(_ error: LanguageModelSession.GenerationError) {
        switch error {
        case .exceededContextWindowSize: self = .tooLong
        case .rateLimited: self = .rateLimited
        case .concurrentRequests: self = .busy
        case .guardrailViolation: self = .safetyBlocked
        case .unsupportedLanguageOrLocale: self = .unsupportedLanguage
        case .unsupportedGuide,
             .decodingFailure,
             .assetsUnavailable:
            self = .unknown(error)
        @unknown default:
            self = .unknown(error)
        }
    }
}
