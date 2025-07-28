// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Errors produced by LiteLLMClient, with user-friendly descriptions.
public enum LLMClientError: LocalizedError {
    case requestCreationFailed
    case invalidResponse
    case noContent
    case decodingFailed
    case networkError(underlying: Error)

    public var errorDescription: String {
        switch self {
        case .requestCreationFailed:
            return "Unable to prepare the request. Please try again later."
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .noContent:
            return "The server returned no message."
        case .decodingFailed:
            return "Failed to read the server's response."
        case .networkError:
            return "Network error occurred. Check your connection and try again."
        }
    }
}
