/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import os.log

/// Indicates an error occurred while calling into the places storage layer
public enum PlacesError: LocalizedError {
    /// This indicates an attempt to use a connection after the PlacesAPI
    /// it came from is destroyed. This indicates a usage error of this library.
    case connUseAfterAPIClosed

    /// This is a catch-all error code used for errors not yet exposed to consumers,
    /// typically since it doesn't seem like there's a sane way for them to be handled.
    case unexpected(message: String)

    /// The rust code implementing places storage paniced. This always indicates a bug.
    case panic(message: String)

    /// The place we were given is invalid.
    case invalidPlace(message: String)

    /// We failed to parse the provided URL.
    case urlParseError(message: String)

    /// The requested operation failed because the database was busy
    /// performing operations on a separate connection to the same DB.
    case databaseBusy(message: String)

    /// The requested operation failed because it was interrupted
    case databaseInterrupted(message: String)

    /// The requested operation failed because the store is corrupt
    case databaseCorrupt(message: String)

    /// Thrown on insertions and updates that specify a parent which
    /// is not a folder
    case invalidParent(message: String)

    /// Thrown on insertions and updates that specify a GUID which
    /// does not exist.
    case noSuchItem(message: String)

    /// Thrown on insertions and updates that attempt to insert or
    /// update a bookmark URL beyond the maximum length of
    /// 65536 bytes.
    case urlTooLong(message: String)

    /// Thrown when attempting to update a bookmark in an illegal way,
    /// for example, trying to set the URL of a folder, the title of
    /// a separator, etc.
    case illegalChange(message: String)

    /// Thrown when attempting to update or delete a root, or
    /// insert a new item as a child of root________.
    case cannotUpdateRoot(message: String)

    /// Our implementation of the localizedError protocol -- (This shows up in Sentry)
    public var errorDescription: String? {
        switch self {
        case .connUseAfterAPIClosed:
            return "PlacesError.connUseAfterAPIClosed"
        case let .unexpected(message):
            return "PlacesError.unexpected: \(message)"
        case let .panic(message):
            return "PlacesError.panic: \(message)"
        case let .invalidPlace(message):
            return "PlacesError.invalidPlace: \(message)"
        case let .urlParseError(message):
            return "PlacesError.urlParseError: \(message)"
        case let .databaseBusy(message):
            return "PlacesError.databaseBusy: \(message)"
        case let .databaseInterrupted(message):
            return "PlacesError.databaseInterrupted: \(message)"
        case let .databaseCorrupt(message):
            return "PlacesError.databaseCorrupt: \(message)"
        case let .invalidParent(message):
            return "PlacesError.invalidParent: \(message)"
        case let .noSuchItem(message):
            return "PlacesError.noSuchItem: \(message)"
        case let .urlTooLong(message):
            return "PlacesError.urlTooLong: \(message)"
        case let .illegalChange(message):
            return "PlacesError.illegalChange: \(message)"
        case let .cannotUpdateRoot(message):
            return "PlacesError.cannotUpdateRoot: \(message)"
        }
    }

    // The name is attempting to indicate that we free rustError.message if it
    // existed, and that it's a very bad idea to touch it after you call this
    // function
    static func fromConsuming(_ rustError: PlacesRustError) -> PlacesError? {
        let message = rustError.message

        switch rustError.code {
        case Places_NoError:
            return nil

        case Places_Panic:
            return .panic(message: String(freeingPlacesString: message!))

        case Places_UnexpectedError:
            return .unexpected(message: String(freeingPlacesString: message!))

        case Places_UrlParseError:
            return .urlParseError(message: String(freeingPlacesString: message!))

        case Places_DatabaseBusy:
            return .databaseBusy(message: String(freeingPlacesString: message!))

        case Places_DatabaseInterrupted:
            return .databaseInterrupted(message: String(freeingPlacesString: message!))

        case Places_InvalidPlace_InvalidParent:
            return .invalidParent(message: String(freeingPlacesString: message!))

        case Places_InvalidPlace_NoSuchItem:
            return .noSuchItem(message: String(freeingPlacesString: message!))

        case Places_InvalidPlace_UrlTooLong:
            return .urlTooLong(message: String(freeingPlacesString: message!))

        case Places_InvalidPlace_IllegalChange:
            return .illegalChange(message: String(freeingPlacesString: message!))

        case Places_InvalidPlace_CannotUpdateRoot:
            return .cannotUpdateRoot(message: String(freeingPlacesString: message!))

        case Places_Corrupt:
            return .databaseCorrupt(message: String(freeingPlacesString: message!))

        default:
            return .unexpected(message: String(freeingPlacesString: message!))
        }
    }

    @discardableResult
    static func tryUnwrap<T>(_ callback: (UnsafeMutablePointer<PlacesRustError>) throws -> T?) throws -> T? {
        var err = PlacesRustError(code: Places_NoError, message: nil)
        let returnedVal = try callback(&err)
        if let placesErr = PlacesError.fromConsuming(err) {
            throw placesErr
        }
        guard let result = returnedVal else {
            return nil
        }
        return result
    }

    @discardableResult
    static func unwrap<T>(_ callback: (UnsafeMutablePointer<PlacesRustError>) throws -> T?) throws -> T {
        guard let result = try PlacesError.tryUnwrap(callback) else {
            throw ResultError.empty
        }
        return result
    }

    // Same as `tryUnwrap`, but instead of erroring, just logs. Useful for cases like destructors where we
    // cannot throw.
    @discardableResult
    static func unwrapOrLog<T>(_ callback: (UnsafeMutablePointer<PlacesRustError>) throws -> T?) -> T? {
        do {
            let result = try PlacesError.tryUnwrap(callback)
            return result
        } catch let e {
            // Can't log what the error is without jumping through hoops apparently, oh well...
            os_log("Hit places error when throwing is impossible %{public}@", type: .error, "\(e)")
            return nil
        }
    }
}
