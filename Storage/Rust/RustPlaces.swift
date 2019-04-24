/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

@_exported import MozillaAppServices

private let log = Logger.syncLogger

public class RustPlaces {
    let databasePath: String

    let writerQueue: DispatchQueue
    let readerQueue: DispatchQueue

    var api: PlacesAPI?

    var writer: PlacesWriteConnection?
    var reader: PlacesReadConnection?

    public fileprivate(set) var isOpen: Bool = false

    private var didAttemptToMoveToBackup = false

    public init(databasePath: String) {
        self.databasePath = databasePath

        self.writerQueue = DispatchQueue(label: "RustPlaces writer queue: \(databasePath)", attributes: [])
        self.readerQueue = DispatchQueue(label: "RustPlaces reader queue: \(databasePath)", attributes: [])

        _ = reopenIfClosed()
    }

    private func open() -> NSError? {
        do {
            api = try PlacesAPI(path: databasePath)
            isOpen = true
            return nil
        } catch let err as NSError {
            if let placesError = err as? PlacesError {
                switch placesError {
                case .panic(let message):
                    Sentry.shared.sendWithStacktrace(message: "Panicked when opening Rust Places database", tag: SentryTag.rustPlaces, severity: .error, description: message)
                default:
                    Sentry.shared.sendWithStacktrace(message: "Unspecified or other error when opening Rust Places database", tag: SentryTag.rustPlaces, severity: .error, description: placesError.localizedDescription)
                }
            } else {
                Sentry.shared.sendWithStacktrace(message: "Unknown error when opening Rust Places database", tag: SentryTag.rustPlaces, severity: .error, description: err.localizedDescription)
            }

            return err
        }
    }

    private func close() -> NSError? {
        api = nil
        writer = nil
        reader = nil
        isOpen = false
        return nil
    }

    private func withWriter<T>(_ callback: @escaping(_ connection: PlacesWriteConnection) throws -> T) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        writerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
                return
            }

            if self.writer == nil {
                self.writer = self.api?.getWriter()
            }

            if let writer = self.writer {
                do {
                    let result = try callback(writer)
                    deferred.fill(Maybe(success: result))
                } catch let error {
                    deferred.fill(Maybe(failure: error as MaybeErrorType))
                }
            } else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
            }
        }

        return deferred
    }

    private func withReader<T>(_ callback: @escaping(_ connection: PlacesReadConnection) throws -> T) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        readerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
                return
            }

            if self.reader == nil {
                do {
                    self.reader = try self.api?.openReader()
                } catch let error {
                    deferred.fill(Maybe(failure: error as MaybeErrorType))
                }
            }

            if let reader = self.reader {
                do {
                    let result = try callback(reader)
                    deferred.fill(Maybe(success: result))
                } catch let error {
                    deferred.fill(Maybe(failure: error as MaybeErrorType))
                }
            } else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
            }
        }

        return deferred
    }

    public func getBookmarksTree(rootGUID: GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNode?>> {
        return withReader { connection in
            return try connection.getBookmarksTree(rootGUID: rootGUID, recursive: recursive)
        }
    }

    public func getBookmark(guid: GUID) -> Deferred<Maybe<BookmarkNode?>> {
        return withReader { connection in
            return try connection.getBookmark(guid: guid)
        }
    }

    public func getBookmarksWithURL(url: String) -> Deferred<Maybe<[BookmarkItem]>> {
        return withReader { connection in
            return try connection.getBookmarksWithURL(url: url)
        }
    }

    public func isBookmarked(url: String) -> Deferred<Maybe<Bool>> {
        return getBookmarksWithURL(url: url).bind { result in
            guard let bookmarks = result.successValue else {
                return deferMaybe(false)
            }

            return deferMaybe(!bookmarks.isEmpty)
        }
    }

    public func searchBookmarks(query: String, limit: UInt) -> Deferred<Maybe<[BookmarkItem]>> {
        return withReader { connection in
            return try connection.searchBookmarks(query: query, limit: limit)
        }
    }

    public func interruptWriter() {
        writer?.interrupt()
    }

    public func interruptReader() {
        reader?.interrupt()
    }

    public func runMaintenance() {
        _ = withWriter { connection in
            try connection.runMaintenance()
        }
    }

    public func deleteBookmarkNode(guid: GUID) -> Success {
        return withWriter { connection in
            let result = try connection.deleteBookmarkNode(guid: guid)
            if !result {
                log.debug("Bookmark with GUID \(guid) does not exist.")
            }
        }
    }

    public func deleteBookmarksWithURL(url: String) -> Success {
        return getBookmarksWithURL(url: url) >>== { bookmarks in
            let deferreds = bookmarks.map({ self.deleteBookmarkNode(guid: $0.guid) })
            return all(deferreds).bind { results in
                if let error = results.find({ $0.isFailure })?.failureValue {
                    return deferMaybe(error)
                }

                return succeed()
            }
        }
    }

    public func createFolder(parentGUID: GUID, title: String, position: UInt32? = nil) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            return try connection.createFolder(parentGUID: parentGUID, title: title, position: position)
        }
    }

    public func createSeparator(parentGUID: GUID, position: UInt32? = nil) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            return try connection.createSeparator(parentGUID: parentGUID, position: position)
        }
    }

    public func createBookmark(parentGUID: GUID, url: String, title: String?, position: UInt32? = nil) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            return try connection.createBookmark(parentGUID: parentGUID, url: url, title: title, position: position)
        }
    }

    public func updateBookmarkNode(guid: GUID, parentGUID: GUID? = nil, position: UInt32? = nil, title: String? = nil, url: String? = nil) -> Success {
        return withWriter { connection in
            return try connection.updateBookmarkNode(guid: guid, parentGUID: parentGUID, position: position, title: title, url: url)
        }
    }

    public func reopenIfClosed() -> NSError? {
        var error: NSError?  = nil

        writerQueue.sync {
            guard !isOpen else { return }

            error = open()
        }

        return error
    }

    public func forceClose() -> NSError? {
        var error: NSError? = nil

        writerQueue.sync {
            guard isOpen else { return }

            error = close()
        }

        return error
    }

    public func sync(unlockInfo: SyncUnlockInfo) -> Success {
        let deferred = Success()

        writerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
                return
            }

            do {
                try self.api?.syncBookmarks(unlockInfo: unlockInfo)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                if let placesError = err as? PlacesError {
                    switch placesError {
                    case .panic(let message):
                        Sentry.shared.sendWithStacktrace(message: "Panicked when syncing Places database", tag: SentryTag.rustPlaces, severity: .error, description: message)
                    default:
                        Sentry.shared.sendWithStacktrace(message: "Unspecified or other error when syncing Places database", tag: SentryTag.rustPlaces, severity: .error, description: placesError.localizedDescription)
                    }
                }

                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func reset() -> Success {
        let deferred = Success()

        writerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesError.connUseAfterAPIClosed as MaybeErrorType))
                return
            }

            // TODO: Call Rust API
            deferred.fill(Maybe(success: ()))
        }

        return deferred
    }
}
