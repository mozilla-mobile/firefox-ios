/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public enum FirefoxAccountError: LocalizedError {
    case unauthorized(message: String)
    case network(message: String)
    case unspecified(message: String)
    case panic(message: String)

    // Trying to finish an authentication that was never started with begin(...)Flow.
    case noExistingAuthFlow
    // Trying to finish a different authentication flow.
    case wrongAuthFlow

    /// Our implementation of the localizedError protocol -- (This shows up in Sentry)
    public var errorDescription: String? {
        switch self {
        case let .unauthorized(message):
            return "FirefoxAccountError.unauthorized: \(message)"
        case let .network(message):
            return "FirefoxAccountError.network: \(message)"
        case let .unspecified(message):
            return "FirefoxAccountError.unspecified: \(message)"
        case let .panic(message):
            return "FirefoxAccountError.panic: \(message)"
        case .noExistingAuthFlow:
            return "FirefoxAccountError.noExistingAuthFlow"
        case .wrongAuthFlow:
            return "FirefoxAccountError.wrongAuthFlow"
        }
    }

    // The name is attempting to indicate that we free fxaError.message if it
    // existed, and that it's a very bad idea to touch it after you call this
    // function
    static func fromConsuming(_ rustError: FxAError) -> FirefoxAccountError? {
        let message = rustError.message
        switch rustError.code {
        case FxA_NoError:
            return nil
        case FxA_NetworkError:
            return .network(message: String(freeingFxaString: message!))
        case FxA_AuthenticationError:
            return .unauthorized(message: String(freeingFxaString: message!))
        case FxA_Other:
            return .unspecified(message: String(freeingFxaString: message!))
        case FxA_InternalPanic:
            return .panic(message: String(freeingFxaString: message!))
        default:
            return .unspecified(message: String(freeingFxaString: message!))
        }
    }

    @discardableResult
    public static func unwrap<T>(_ callback: (UnsafeMutablePointer<FxAError>) throws -> T?) throws -> T {
        guard let result = try tryUnwrap(callback) else {
            throw ResultError.empty
        }
        return result
    }

    @discardableResult
    public static func tryUnwrap<T>(_ callback: (UnsafeMutablePointer<FxAError>) throws -> T?) throws -> T? {
        var err = FxAError(code: FxA_NoError, message: nil)
        let returnedVal = try callback(&err)
        if let fxaErr = FirefoxAccountError.fromConsuming(err) {
            throw fxaErr
        }
        return returnedVal
    }
}
