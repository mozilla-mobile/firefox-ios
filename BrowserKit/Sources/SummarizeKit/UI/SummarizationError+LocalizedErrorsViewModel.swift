// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ErrorButtonState {
    case retry, close, acceptToS
}

extension SummarizerError {
    var shouldRetrySummarizing: ErrorButtonState {
        return switch self {
        case .busy,
             .noContent,
             .invalidResponse,
             .invalidChunk:
            .retry
        case .tosConsentMissing:
            .acceptToS
        default:
            .close
        }
    }

    func description(for localizedErrors: LocalizedErrorsViewConfiguration) -> String {
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
        case .tosConsentMissing:
            ""
        }
    }

    func errorButtonLabel(for configuration: SummarizeViewConfiguration) -> String {
        return switch shouldRetrySummarizing {
        case .retry:
            configuration.errorMessages.retryButtonLabel
        case .close:
            configuration.errorMessages.closeButtonLabel
        case .acceptToS:
            configuration.termOfService.allowButtonTitle
        }
    }

    func errorButtonA11yLabel(for configuration: SummarizeViewConfiguration) -> String {
        return switch shouldRetrySummarizing {
        case .retry:
            configuration.errorMessages.retryButtonA11yLabel
        case .close:
            configuration.errorMessages.closeButtonA11yLabel
        case .acceptToS:
            configuration.termOfService.allowButtonA11yLabel
        }
    }

    func errorButtonA11yId(for configuration: SummarizeViewConfiguration) -> String {
        return switch shouldRetrySummarizing {
        case .retry:
            configuration.errorMessages.retryButtonA11yId
        case .close:
            configuration.errorMessages.closeButtonA11yId
        case .acceptToS:
            configuration.termOfService.allowButtonA11yId
        }
    }
}
