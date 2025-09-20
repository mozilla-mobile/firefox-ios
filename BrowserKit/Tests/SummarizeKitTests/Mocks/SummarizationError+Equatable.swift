// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

/// NOTE: Conforming Equatable to make checks in tests simpler.
extension SummarizerError: Equatable {
    public static func == (lhs: SummarizerError, rhs: SummarizerError) -> Bool {
        switch (lhs, rhs) {
        case (.tooLong, .tooLong),
             (.rateLimited, .rateLimited),
             (.busy, .busy),
             (.safetyBlocked, .safetyBlocked),
             (.unsupportedLanguage, .unsupportedLanguage),
             (.invalidResponse, .invalidResponse),
             (.unableToExtractContent, .unableToExtractContent),
             (.invalidChunk, .invalidChunk),
             (.noContent, .noContent),
             (.tosConsentMissing, .tosConsentMissing),
             (.cancelled, .cancelled):
            return true

        case (.unknown(let lhsError), .unknown(let rhsError)):
            return String(describing: lhsError) == String(describing: rhsError)

        default:
            return false
        }
    }
}
