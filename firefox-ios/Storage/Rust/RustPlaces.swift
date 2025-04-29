// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

import class MozillaAppServices.BookmarkItemData
import class MozillaAppServices.BookmarkNodeData
import class MozillaAppServices.PlacesAPI
import class MozillaAppServices.PlacesReadConnection
import class MozillaAppServices.PlacesWriteConnection
import enum MozillaAppServices.FrecencyThresholdOption
import enum MozillaAppServices.PlacesApiError
import enum MozillaAppServices.PlacesConnectionError
import enum MozillaAppServices.VisitType
import struct MozillaAppServices.HistoryMetadataKey
import struct MozillaAppServices.HistoryMigrationResult
import struct MozillaAppServices.HistoryVisitInfosWithBound
import struct MozillaAppServices.PlacesTimestamp
import struct MozillaAppServices.SearchResult
import struct MozillaAppServices.TopFrecentSiteInfo
import struct MozillaAppServices.Url
import struct MozillaAppServices.VisitObservation
import struct MozillaAppServices.VisitTransitionSet

public protocol BookmarksHandler {
    func getRecentBookmarks(limit: UInt, completion: @escaping ([BookmarkItemData]) -> Void)
    func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool,
        completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
    )
    func getBookmarksTree(rootGUID: GUID, recursive: Bool) -> Deferred<Maybe<BookmarkNodeData?>>
    func countBookmarksInTrees(folderGuids: [GUID], completion: @escaping (Result<Int, Error>) -> Void)
    func updateBookmarkNode(
        guid: GUID,
        parentGUID: GUID?,
        position: UInt32?,
        title: String?,
        url: String?
    ) -> Success

    func updateBookmarkNode(
        guid: GUID,
        parentGUID: GUID?,
        position: UInt32?,
        title: String?,
        url: String?,
        completion: @escaping (Result<Void, any Error>) -> Void
    )
}

public class RustPlaces: BookmarksHandler {
    let databasePath: String

    let writerQueue: DispatchQueue
    let readerQueue: DispatchQueue

    public var api: PlacesAPI?

    public var writer: PlacesWriteConnection?
    public var reader: PlacesReadConnection?

    public fileprivate(set) var isOpen = false

    private var didAttemptToMoveToBackup = false
    private var notificationCenter: NotificationCenter
    private var logger: Logger

    public init(databasePath: String,
                notificationCenter: NotificationCenter = NotificationCenter.default,
                logger: Logger = DefaultLogger.shared) {
        self.databasePath = databasePath
        self.notificationCenter = notificationCenter
        self.logger = logger
        self.writerQueue = DispatchQueue(label: "RustPlaces writer queue: \(databasePath)", attributes: [])
        self.readerQueue = DispatchQueue(label: "RustPlaces reader queue: \(databasePath)", attributes: [])
    }

    private func open() -> NSError? {
        do {
            api = try PlacesAPI(path: databasePath)
            isOpen = true
            notificationCenter.post(name: .RustPlacesOpened, object: nil)
            return nil
        } catch let err as NSError {
            if let placesError = err as? PlacesApiError {
                logger.log("Places error when opening Rust Places database",
                           level: .warning,
                           category: .storage,
                           description: placesError.localizedDescription)
            } else {
                logger.log("Unknown error when opening Rust Places database",
                           level: .warning,
                           category: .storage,
                           description: err.localizedDescription)
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

    private func withWriter<T>(
        _ callback: @escaping(_ connection: PlacesWriteConnection) throws -> T
    ) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        writerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesConnectionError.connUseAfterApiClosed as MaybeErrorType))
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
                deferred.fill(Maybe(failure: PlacesConnectionError.connUseAfterApiClosed as MaybeErrorType))
            }
        }

        return deferred
    }

    /// This method is reimplemented with a completion handler because we want to incrementally get rid of using `Deferred`.
    public func withWriter<T>(
        _ callback: @escaping (
            PlacesWriteConnection
        ) throws -> T,
        completion: @escaping (Result<T, any Error>) -> Void
    ) {
        writerQueue.async {
            guard self.isOpen else {
                completion(.failure(PlacesConnectionError.connUseAfterApiClosed))
                return
            }

            if self.writer == nil {
                self.writer = self.api?.getWriter()
            }

            if let writer = self.writer {
                do {
                    let result = try callback(writer)
                    completion(.success(result))
                } catch let error {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(PlacesConnectionError.connUseAfterApiClosed))
            }
        }
    }

    private func withReader<T>(
        _ callback: @escaping(_ connection: PlacesReadConnection) throws -> T
    ) -> Deferred<Maybe<T>> {
        let deferred = Deferred<Maybe<T>>()

        readerQueue.async {
            guard self.isOpen else {
                deferred.fill(Maybe(failure: PlacesConnectionError.connUseAfterApiClosed as MaybeErrorType))
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
                deferred.fill(Maybe(failure: PlacesConnectionError.connUseAfterApiClosed as MaybeErrorType))
            }
        }

        return deferred
    }

    /// This method is reimplemented with a completion handler because we want to incrementally get rid of using `Deferred`.
    private func withReader<T>(
        _ callback: @escaping (
            PlacesReadConnection
        ) throws -> T,
        completion: @escaping (Result<T, any Error>) -> Void
    ) {
        readerQueue.async {
            guard self.isOpen else {
                completion(.failure(PlacesConnectionError.connUseAfterApiClosed))
                return
            }

            if self.reader == nil {
                do {
                    self.reader = try self.api?.openReader()
                } catch let error {
                    completion(.failure(error))
                    return
                }
            }

            if let reader = self.reader {
                do {
                    let result = try callback(reader)
                    completion(.success(result))
                } catch let error {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(PlacesConnectionError.connUseAfterApiClosed))
            }
        }
    }

    public func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool
    ) -> Deferred<Maybe<BookmarkNodeData?>> {
        return withReader { connection in
            return try connection.getBookmarksTree(rootGUID: rootGUID, recursive: recursive)
        }
    }

    public func getBookmarksTree(
        rootGUID: GUID,
        recursive: Bool,
        completion: @escaping (Result<BookmarkNodeData?, any Error>) -> Void
    ) {
        withReader({ connection in
            return try connection.getBookmarksTree(
                rootGUID: rootGUID,
                recursive: recursive
            )
        }, completion: completion)
    }

    public func getBookmark(guid: GUID) -> Deferred<Maybe<BookmarkNodeData?>> {
        return withReader { connection in
            return try connection.getBookmark(guid: guid)
        }
    }

    public func getRecentBookmarks(
        limit: UInt,
        completion: @escaping ([BookmarkItemData]) -> Void
    ) {
        let deferredResponse = withReader { connection in
            return try connection.getRecentBookmarks(limit: limit)
        }

        deferredResponse.upon { result in
            completion(result.successValue ?? [])
        }
    }

    public func countBookmarksInTrees(folderGuids: [GUID], completion: @escaping (Result<Int, Error>) -> Void) {
        let deferredResponse = withReader { connection in
            return try connection.countBookmarksInTrees(folderGuids: folderGuids)
        }

        deferredResponse.upon { result in
            if let count = result.successValue {
                completion(.success(count))
            } else if let error = result.failureValue {
                completion(.failure(error))
            }
        }
    }

    public func getRecentBookmarks(limit: UInt) -> Deferred<Maybe<[BookmarkItemData]>> {
        return withReader { connection in
            return try connection.getRecentBookmarks(limit: limit)
        }
    }

    public func getBookmarkURLForKeyword(keyword: String) -> Deferred<Maybe<String?>> {
        return withReader { connection in
            return try connection.getBookmarkURLForKeyword(keyword: keyword)
        }
    }

    public func getBookmarksWithURL(url: String) -> Deferred<Maybe<[BookmarkItemData]>> {
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

    public func searchBookmarks(
        query: String,
        limit: UInt
    ) -> Deferred<Maybe<[BookmarkItemData]>> {
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

    public func runMaintenance(dbSizeLimit: UInt32) {
        _ = withWriter { connection in
            try connection.runMaintenance(dbSizeLimit: dbSizeLimit)
        }
    }

    public func deleteBookmarkNode(guid: GUID) -> Success {
        return withWriter { connection in
            let result = try connection.deleteBookmarkNode(guid: guid)
            guard result else {
                self.logger.log("Bookmark with GUID \(guid) does not exist.",
                                level: .debug,
                                category: .storage)
                return
            }

            self.notificationCenter.post(name: .BookmarksUpdated, object: self)
        }
    }

    public func deleteBookmarksWithURL(url: String) -> Success {
        return getBookmarksWithURL(url: url) >>== { bookmarks in
            let deferreds = bookmarks.map({ self.deleteBookmarkNode(guid: $0.guid) })
            return all(deferreds).bind { results in
                if let error = results.first(where: { $0.isFailure })?.failureValue {
                    return deferMaybe(error)
                }

                self.notificationCenter.post(name: .BookmarksUpdated, object: self)
                return succeed()
            }
        }
    }

    public func createFolder(parentGUID: GUID, title: String,
                             position: UInt32?) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            return try connection.createFolder(
                parentGUID: parentGUID,
                title: title,
                position: position
            )
        }
    }

    /// This method is reimplemented with a completion handler because we want to incrementally get rid of using `Deferred`.
    public func createFolder(parentGUID: GUID, title: String,
                             position: UInt32?,
                             completion: @escaping (Result<GUID, any Error>) -> Void) {
        withWriter({ connection in
                return try connection.createFolder(
                    parentGUID: parentGUID,
                    title: title,
                    position: position
                )
            }, completion: completion)
    }

    public func createSeparator(parentGUID: GUID,
                                position: UInt32?) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            return try connection.createSeparator(
                parentGUID: parentGUID,
                position: position
            )
        }
    }

    @discardableResult
    public func createBookmark(parentGUID: GUID,
                               url: String,
                               title: String?,
                               position: UInt32?) -> Deferred<Maybe<GUID>> {
        return withWriter { connection in
            let response = try connection.createBookmark(
                parentGUID: parentGUID,
                url: url,
                title: title,
                position: position
            )
            self.notificationCenter.post(name: .BookmarksUpdated, object: self)
            return response
        }
    }

    /// This method is reimplemented with a completion handler because we want to incrementally get rid of using `Deferred`.
    public func createBookmark(
        parentGUID: GUID,
        url: String,
        title: String?,
        position: UInt32?,
        completion: @escaping (Result<GUID, any Error>) -> Void
    ) {
        withWriter({ connection in
                let response = try connection.createBookmark(
                    parentGUID: parentGUID,
                    url: url,
                    title: title,
                    position: position
                )
                self.notificationCenter.post(name: .BookmarksUpdated, object: self)
                return response
            }, completion: completion)
    }

    public func updateBookmarkNode(
        guid: GUID,
        parentGUID: GUID? = nil,
        position: UInt32? = nil,
        title: String? = nil,
        url: String? = nil
    ) -> Success {
        return withWriter { connection in
            return try connection.updateBookmarkNode(
                guid: guid,
                parentGUID: parentGUID,
                position: position,
                title: title,
                url: url
            )
        }
    }

    /// This method is reimplemented with a completion handler because we want to incrementally get rid of using `Deferred`.
    public func updateBookmarkNode(
        guid: Shared.GUID,
        parentGUID: Shared.GUID? = nil,
        position: UInt32? = nil,
        title: String? = nil,
        url: String? = nil,
        completion: @escaping (Result<Void, any Error>) -> Void
    ) {
        withWriter({ connection in
                return try connection.updateBookmarkNode(
                    guid: guid,
                    parentGUID: parentGUID,
                    position: position,
                    title: title,
                    url: url
                )
            }, completion: completion)
    }

    public func reopenIfClosed() -> NSError? {
        var error: NSError?

        writerQueue.sync {
            guard !isOpen else { return }

            error = open()
        }

        return error
    }

    public func forceClose() -> NSError? {
        var error: NSError?

        writerQueue.sync {
            guard isOpen else { return }

            error = close()
        }

        return error
    }

    public func registerWithSyncManager() {
        writerQueue.async { [unowned self] in
            self.api?.registerWithSyncManager()
        }
    }

    // MARK: History metadata
    // We are not collecting history metadata anymore since FXIOS-6729, but let's keep the possibility
    // to delete metadata for a while.
    public func deleteHistoryMetadataOlderThan(olderThan: Int64) -> Deferred<Maybe<Void>> {
        return withWriter { connection in
            let response: Void = try connection.deleteHistoryMetadataOlderThan(olderThan: olderThan)
            return response
        }
    }

    private func deleteHistoryMetadata(since startDate: Int64) -> Deferred<Maybe<Void>> {
        let now = Date().toMillisecondsSince1970()
        return withWriter { connection in
            return try connection.deleteVisitsBetween(start: startDate, end: now)
        }
    }

    public func deleteHistoryMetadata(
        since startDate: Int64,
        completion: @escaping (Bool) -> Void
    ) {
        let deferredResponse = deleteHistoryMetadata(since: startDate)
        deferredResponse.upon { result in
            completion(result.isSuccess)
        }
    }

    private func migrateHistory(dbPath: String, lastSyncTimestamp: Int64) -> Deferred<Maybe<HistoryMigrationResult>> {
        return withWriter { connection in
            return try connection.migrateHistoryFromBrowserDb(path: dbPath, lastSyncTimestamp: lastSyncTimestamp)
        }
    }

    public func migrateHistory(
        dbPath: String,
        lastSyncTimestamp: Int64,
        completion: @escaping (HistoryMigrationResult) -> Void,
        errCallback: @escaping (Error?) -> Void
    ) {
        _ = reopenIfClosed()
        let deferredResponse = self.migrateHistory(dbPath: dbPath, lastSyncTimestamp: lastSyncTimestamp)
        deferredResponse.upon { result in
            guard result.isSuccess, let result = result.successValue else {
                errCallback(result.failureValue)
                return
            }
            completion(result)
        }
    }

    public func deleteVisitsFor(url: Url) -> Deferred<Maybe<Void>> {
        return withWriter { connection in
            return try connection.deleteVisitsFor(url: url)
        }
    }
}

// MARK: History APIs

// WKWebView has these:
/*
WKNavigationTypeLinkActivated,
WKNavigationTypeFormSubmitted,
WKNavigationTypeBackForward,
WKNavigationTypeReload,
WKNavigationTypeFormResubmitted,
WKNavigationTypeOther = -1,
*/

// Enums in Swift aren't implicitly defaulted to Int, and Uniffi doesn't
// provide an easy way to define the enum type we should remove this once
// https://github.com/mozilla/uniffi-rs/issues/1792 is implemented
extension VisitType {
    public static func fromRawValue(rawValue: Int?) -> Self {
        switch rawValue {
        case 1: return .link
        case 2: return .typed
        case 3: return .bookmark
        case 4: return .embed
        case 5: return .redirectPermanent
        case 6: return .redirectTemporary
        case 7: return .download
        case 8: return .framedLink
        case 9: return .reload
        case 10: return .updatePlace
        // .unknown and .recentlyClosed used to just == .link
        default: return .link
        }
    }

    public var rawValue: Int? {
        switch self {
        case .link:              return 1
        case .typed:             return 2
        case .bookmark:          return 3
        case .embed:             return 4
        case .redirectPermanent: return 5
        case .redirectTemporary: return 6
        case .download:          return 7
        case .framedLink:        return 8
        case .reload:            return 9
        case .updatePlace:       return 10
        }
    }
}

extension RustPlaces {
    public func applyObservation(visitObservation: VisitObservation) -> Success {
        return withWriter { connection in
            return try connection.applyObservation(visitObservation: visitObservation)
        }.map { result in
            self.notificationCenter.post(name: .TopSitesUpdated, object: nil)
            return result
        }
    }

    public func deleteEverythingHistory() -> Success {
        return withWriter { connection in
            return try connection.deleteEverythingHistory()
        }
    }

    public func deleteVisitsFor(_ url: String) -> Success {
        return withWriter { connection in
            return try connection.deleteVisitsFor(url: url)
        }
    }

    public func deleteVisitsBetween(_ date: Date) -> Success {
        return withWriter { connection in
            return try connection.deleteVisitsBetween(start: PlacesTimestamp(date.toMillisecondsSince1970()),
                                                      end: PlacesTimestamp(Date().toMillisecondsSince1970()))
        }
    }

    public func queryAutocomplete(
        matchingSearchQuery filter: String,
        limit: Int
    ) -> Deferred<Maybe<[SearchResult]>> {
        return withReader { connection in
            return try connection.queryAutocomplete(search: filter, limit: Int32(limit))
        }
    }

    public func getVisitPageWithBound(
        limit: Int,
        offset: Int,
        excludedTypes: VisitTransitionSet
    ) -> Deferred<Maybe<HistoryVisitInfosWithBound>> {
        return withReader { connection in
            return try connection.getVisitPageWithBound(bound: Int64(Date().toMillisecondsSince1970()),
                                                        offset: Int64(offset),
                                                        count: Int64(limit),
                                                        excludedTypes: excludedTypes)
        }
    }

    public func getTopFrecentSiteInfos(
        limit: Int,
        thresholdOption: FrecencyThresholdOption
    ) -> Deferred<Maybe<[Site]>> {
        let deferred: Deferred<Maybe<[TopFrecentSiteInfo]>> = withReader { connection in
            return try connection.getTopFrecentSiteInfos(numItems: Int32(limit), thresholdOption: thresholdOption)
        }

        let returnValue = Deferred<Maybe<[Site]>>()
        deferred.upon { result in
            guard let result = result.successValue else {
                returnValue.fill(Maybe(failure: result.failureValue ?? "Unknown Error"))
                return
            }
            returnValue.fill(Maybe(success: result.map { info in
                var title: String
                if let actualTitle = info.title, !actualTitle.isEmpty {
                    title = actualTitle
                } else {
                    // In case there is no title, we use the url
                    // as the title
                    title = info.url
                }
                return Site.createBasicSite(url: info.url, title: title)
            }))
        }
        return returnValue
    }

    public func getSitesWithBound(
        limit: Int,
        offset: Int,
        excludedTypes: VisitTransitionSet
    ) -> Deferred<Maybe<Cursor<Site>>> {
        let deferred = getVisitPageWithBound(limit: limit, offset: offset, excludedTypes: excludedTypes)
        let result = Deferred<Maybe<Cursor<Site>>>()
        deferred.upon { [weak self] visitInfos in
            guard let visitInfos = visitInfos.successValue else {
                result.fill(Maybe(failure: visitInfos.failureValue ?? "Unknown Error"))
                return
            }
            let sites = visitInfos.infos.map { info -> Site in
                var title: String
                if let actualTitle = info.title, !actualTitle.isEmpty {
                    title = actualTitle
                } else {
                    // In case there is no title, we use the url
                    // as the title
                    title = info.url
                }
                // Note: FXIOS-10740 Necessary to have unique Site ID iOS 18 HistoryPanel crash with diffable data sources
                let hashValue = "\(info.url)_\(info.timestamp)".hashValue
                var site = Site.createBasicSite(id: hashValue, url: info.url, title: title)
                site.latestVisit = Visit(date: UInt64(info.timestamp) * 1000, type: info.visitType)
                return site
            }

            let sitesUniqued = sites.uniqued()

            // FXIOS-10996 Temporary check for duplicates to help diagnose history panel crashes
            if sites.count != sitesUniqued.count {
                let duplicateCount = sitesUniqued.count - sites.count
                self?.logger.log(
                    "RustPlaces sites history returned \(duplicateCount) duplicate Sites",
                    level: .info,
                    category: .library
                )
            }

            result.fill(Maybe(success: ArrayCursor(data: sites)))
        }
        return result
    }
}
