// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension SummarizerError {
    var shouldRetrySummarizing: Bool {
        return switch self {
        case .busy,
             .noContent,
             .invalidResponse,
             .invalidChunk:
            true
        default:
            false
        }
    }

    func description(for localizedErrors: LocalizedErrorsViewModel) -> String {
        return switch self {
        case .rateLimited:
            localizedErrors.rateLimitedMessage
        case .safetyBlocked:
            localizedErrors.unsafeContentMessage
        case .unsupportedLanguage,
             .invalidResponse,
             .tooLong,
             .unableToExtractContent:
            localizedErrors.summarizationNotAvailableMessage
        case .noContent, .busy:
            localizedErrors.pageStillLoadingMessage
        case .unknown, .cancelled, .invalidChunk:
            localizedErrors.genericErrorMessage
        }
    }
}
