/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/// Indicates an error occurred while calling into the logins storage layer
public enum LoginsStoreError: LocalizedError {
    /// This is a catch-all error code used for errors not yet exposed to consumers,
    /// typically since it doesn't seem like there's a sane way for them to be handled.
    case unspecified(message: String)

    /// The rust code implementing logins storage paniced. This always indicates a bug.
    case panic(message: String)

    /// This indicates that the sync authentication is invalid, likely due to having
    /// expired.
    case authInvalid(message: String)

    /// This is thrown if a `touch` or `update` refers to a record whose ID is not known
    case noSuchRecord(message: String)

    /// This is thrown on attempts to `add` a record with a specific ID, but that ID
    /// already exists.
    case duplicateGuid(message: String)

    /// This is thrown on attempts to insert or update a record so that it
    /// is no longer valid. See InvalidLoginReason for list of reasons.
    case invalidLogin(message: String, reason: InvalidLoginReason)

    /// This error is emitted in two cases:
    ///
    /// 1. An incorrect key is used to to open the login database
    /// 2. The file at the path specified is not a sqlite database.
    case invalidKey(message: String)

    /// This error is emitted if a request to a sync server failed.
    case network(message: String)

    /// This error is emitted if a call to `interrupt()` is made to
    /// abort some operation.
    case interrupted(message: String)

    /// This error is emitted if the salt provided to unlock the
    /// database was invalid.
    case invalidSalt(message: String)

    /// Our implementation of the localizedError protocol -- (This shows up in Sentry)
    public var errorDescription: String? {
        switch self {
        case let .unspecified(message):
            return "LoginsStoreError.unspecified: \(message)"
        case let .panic(message):
            return "LoginsStoreError.panic: \(message)"
        case let .authInvalid(message):
            return "LoginsStoreError.authInvalid: \(message)"
        case let .noSuchRecord(message):
            return "LoginsStoreError.noSuchRecord: \(message)"
        case let .duplicateGuid(message):
            return "LoginsStoreError.duplicateGuid: \(message)"
        case let .invalidLogin(message):
            return "LoginsStoreError.invalidLogin: \(message)"
        case let .invalidKey(message):
            return "LoginsStoreError.invalidKey: \(message)"
        case let .network(message):
            return "LoginsStoreError.network: \(message)"
        case let .interrupted(message):
            return "LoginsStoreError.interrupted: \(message)"
        case let .invalidSalt(message):
            return "LoginsStoreError.invalidSalt: \(message)"
        }
    }

    // The name is attempting to indicate that we free rustError.message if it
    // existed, and that it's a very bad idea to touch it after you call this
    // function
    static func fromConsuming(_ rustError: Sync15PasswordsError) -> LoginsStoreError? {
        let message = rustError.message

        switch rustError.code {
        case Sync15Passwords_NoError:
            return nil

        case Sync15Passwords_OtherError:
            return .unspecified(message: String(freeingRustString: message!))

        case Sync15Passwords_UnexpectedPanic:
            return .panic(message: String(freeingRustString: message!))

        case Sync15Passwords_AuthInvalidError:
            return .authInvalid(message: String(freeingRustString: message!))

        case Sync15Passwords_NoSuchRecord:
            return .noSuchRecord(message: String(freeingRustString: message!))

        case Sync15Passwords_DuplicateGuid:
            return .duplicateGuid(message: String(freeingRustString: message!))

        case Sync15Passwords_InvalidLogin_EmptyOrigin:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .emptyOrigin)

        case Sync15Passwords_InvalidLogin_EmptyPassword:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .emptyPassword)

        case Sync15Passwords_InvalidLogin_DuplicateLogin:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .duplicateLogin)

        case Sync15Passwords_InvalidLogin_BothTargets:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .bothTargets)

        case Sync15Passwords_InvalidLogin_NoTarget:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .noTarget)

        case Sync15Passwords_InvalidLogin_IllegalFieldValue:
            return .invalidLogin(message: String(freeingRustString: message!), reason: .illegalFieldValue)

        case Sync15Passwords_InvalidKeyError:
            return .invalidKey(message: String(freeingRustString: message!))

        case Sync15Passwords_NetworkError:
            return .network(message: String(freeingRustString: message!))

        case Sync15Passwords_InterruptedError:
            return .interrupted(message: String(freeingRustString: message!))

        case Sync15Passwords_InvalidSaltError:
            return .invalidSalt(message: String(freeingRustString: message!))

        default:
            return .unspecified(message: String(freeingRustString: message!))
        }
    }

    @discardableResult
    public static func unwrap<T>(_ fn: (UnsafeMutablePointer<Sync15PasswordsError>) throws -> T?) throws -> T {
        var err = Sync15PasswordsError(code: Sync15Passwords_NoError, message: nil)
        guard let result = try fn(&err) else {
            if let loginErr = LoginsStoreError.fromConsuming(err) {
                throw loginErr
            }
            throw ResultError.empty
        }
        // result might not be nil (e.g. it could be 0), while still indicating failure. Ultimately,
        // `err` is the source of truth here.
        if let loginErr = LoginsStoreError.fromConsuming(err) {
            throw loginErr
        }
        return result
    }

    @discardableResult
    public static func tryUnwrap<T>(_ fn: (UnsafeMutablePointer<Sync15PasswordsError>) throws -> T?) throws -> T? {
        var err = Sync15PasswordsError(code: Sync15Passwords_NoError, message: nil)
        guard let result = try fn(&err) else {
            if let loginErr = LoginsStoreError.fromConsuming(err) {
                throw loginErr
            }
            return nil
        }
        // result might not be nil (e.g. it could be 0), while still indicating failure. Ultimately,
        // `err` is the source of truth here.
        if let loginErr = LoginsStoreError.fromConsuming(err) {
            throw loginErr
        }
        return result
    }
}

/// Indicates a record is invalid
public enum InvalidLoginReason {
    case emptyOrigin
    case emptyPassword
    case duplicateLogin
    case bothTargets
    case noTarget
    case illegalFieldValue
}
