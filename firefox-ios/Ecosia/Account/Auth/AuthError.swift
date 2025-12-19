// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Errors that can occur during login and logout operations.
public enum AuthError: Error, LocalizedError {
    case authenticationFailed(Error)
    case credentialsStorageFailed
    case credentialsStorageError(Error)
    case credentialsClearingFailed
    case credentialsRenewalFailed(Error)
    case sessionClearingFailed(Error)
    case userCancelled
    case authFlowConfigurationError(String)
    case authFlowSessionManagementFailed(String)
    case authFlowInvisibleTabCreationFailed

    public var errorDescription: String? {
        switch self {
        case .authenticationFailed(let error):
            return "Authentication failed: \(error.localizedDescription)"
        case .credentialsStorageFailed:
            return "Authentication succeeded but failed to store credentials locally"
        case .credentialsStorageError(let error):
            return "Authentication succeeded but credential storage failed: \(error.localizedDescription)"
        case .credentialsClearingFailed:
            return "Failed to clear stored credentials"
        case .credentialsRenewalFailed(let error):
            return "Failed to renew credentials: \(error.localizedDescription)"
        case .sessionClearingFailed(let error):
            return "Failed to clear web session and credentials: \(error.localizedDescription)"
        case .userCancelled:
            return "User cancelled the authentication operation"
        case .authFlowConfigurationError(let message):
            return "Authentication flow configuration error: \(message)"
        case .authFlowSessionManagementFailed(let message):
            return "Authentication flow session management failed: \(message)"
        case .authFlowInvisibleTabCreationFailed:
            return "Authentication flow failed to create required background tabs"
        }
    }
}
