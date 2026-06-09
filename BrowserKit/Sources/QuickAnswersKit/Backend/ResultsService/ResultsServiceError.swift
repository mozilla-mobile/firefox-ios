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
}
