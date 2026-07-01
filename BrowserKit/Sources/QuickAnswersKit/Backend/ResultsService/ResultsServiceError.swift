// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

enum ResultsServiceError: Error, Equatable {
    case invalidResponse(statusCode: Int)
    case noMessage
    case rateLimited
    case requestCreationFailed
    case maxUsers
    case payloadTooLarge
    case unableToCreateService
    case unknown(String)

    var shouldRetry: Bool {
        switch self {
        case .invalidResponse, .noMessage:
            return false
        default:
            return true
        }
    }

    /// A bounded, PII-free label safe to record in telemetry.
    /// The associated values (including `unknown`'s underlying error description) are intentionally dropped.
    var telemetryLabel: String {
        switch self {
        case .invalidResponse: return "invalid_response"
        case .noMessage: return "no_message"
        case .rateLimited: return "rate_limited"
        case .requestCreationFailed: return "request_creation_failed"
        case .maxUsers: return "max_users"
        case .payloadTooLarge: return "payload_too_large"
        case .unableToCreateService: return "unable_to_create_service"
        case .unknown: return "unknown"
        }
    }
}
