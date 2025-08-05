// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Error types for summarization flows, mapping underlying model errors to user‑friendly cases.
/// The UI layer will rely on userMessage to display appropriate messages.
enum SummarizerError: Error, LocalizedError, Sendable {
    case tooLong
    case rateLimited
    case busy
    case safetyBlocked
    case unsupportedLanguage
    case invalidResponse(statusCode: Int)
    case unableToExtractContent
    case invalidChunk
    case cancelled
    case noContent
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
        case .noContent: return ""
        case .invalidChunk: return ""
        case .unableToExtractContent: return ""
        case .unknown: return ""
        }
    }

    /// Maps from summarization checker reasons
    init(reason: SummarizationReason?) {
        switch reason {
        case .contentTooLong: self = .tooLong
        case .documentLanguageUnsupported: self = .unsupportedLanguage
        case .documentNotReadable: self = .cancelled
        case nil: self = .unableToExtractContent
        }
    }
}

/// We need these compile time checks so the app can be built with pre‑iOS 26 SDKs.
/// Once our BR workflow switches to 26, we can remove them,
/// as the runtime @available checks will be enough.
#if canImport(FoundationModels)
import FoundationModels

extension SummarizerError {
    /// Initialize from `LanguageModelSession.GenerationError`.
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

#endif
