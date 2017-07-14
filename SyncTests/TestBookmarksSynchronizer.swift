/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
@testable import Sync
@testable import Storage

import XCTest
import SwiftyJSON

class MockStorage: LocalItemSource, MirrorItemSource, SyncableBookmarks {
    var local: [GUID: BookmarkMirrorItem] = [:]
    var localAdditions: [GUID] = []
    var lastBufferUpdatedCompletionOpApplied: BufferUpdatedCompletionOp?

    // LocalItemSource methods.

    func getLocalItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        guard let item = self.local[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find item \(guid)."))
        }
        return deferMaybe(item)
    }

    func getLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> where T.Iterator.Element == GUID {
        var acc: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach { guid in
            if let item = self.local[guid] {
                acc[guid] = item
            }
        }
        return deferMaybe(acc)
    }

    func prefetchLocalItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return succeed()
    }

    // MirrorItemSource methods (not implemented!).

    func getMirrorItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func getMirrorItemsWithGUIDs<T>(_ guids: T) -> Deferred<Maybe<[GUID : BookmarkMirrorItem]>> where T : Collection, T.Iterator.Element == GUID {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func prefetchMirrorItemsWithGUIDs<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID {
        return succeed()
    }

    // SyncableBookmarks methods (partialy implemented!).

    func isUnchanged() -> Deferred<Maybe<Bool>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func getLocalBookmarksAdditions(limit: Int) -> Deferred<Maybe<[BookmarkMirrorItem]>> {
        return deferMaybe(self.localAdditions.prefix(limit).flatMap { self.local[$0] })
    }

    func getLocalDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func treesForEdges() -> Deferred<Maybe<(local: BookmarkTree, buffer: BookmarkTree)>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func treeForMirror() -> Deferred<Maybe<BookmarkTree>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func applyLocalOverrideCompletionOp(_ op: LocalOverrideCompletionOp, itemSources: ItemSources) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func applyBufferUpdatedCompletionOp(_ op: BufferUpdatedCompletionOp) -> Success {
        self.lastBufferUpdatedCompletionOpApplied = op
        return succeed()
    }

    // Misc methods.

    func resetClient() -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func onRemovedAccount() -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }
}

class MockBuffer: BookmarkBufferStorage, BufferItemSource {
    var buffer: [GUID: BookmarkMirrorItem] = [:]
    var children: [GUID: [GUID]] = [:]

    // BufferItemSource methods.

    func getBufferItemWithGUID(_ guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        guard let item = self.buffer[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find item \(guid)."))
        }
        return deferMaybe(item)
    }

    func getBufferItemsWithGUIDs<T>(_ guids: T) -> Deferred<Maybe<[GUID : BookmarkMirrorItem]>> where T : Collection, T.Iterator.Element == GUID {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func getBufferChildrenGUIDsForParent(_ guid: GUID) -> Deferred<Maybe<[GUID]>> {
        guard let children = self.children[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find children for \(guid)."))
        }
        return deferMaybe(children)
    }

    func prefetchBufferItemsWithGUIDs<T>(_ guids: T) -> Success where T : Collection, T.Iterator.Element == GUID {
        return succeed()
    }

    // BookmarkBufferStorage methods.

    func isEmpty() -> Deferred<Maybe<Bool>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func applyRecords(_ records: [BookmarkMirrorItem]) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func doneApplyingRecordsAfterDownload() -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func validate() -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func getBufferedDeletions() -> Deferred<Maybe<[(GUID, Timestamp)]>> {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func applyBufferCompletionOp(_ op: BufferCompletionOp, itemSources: ItemSources) -> Success {
        return deferMaybe(DatabaseError(description: "Not implemented"))
    }

    func synchronousBufferCount() -> Int? {
        return nil
    }
}

class TestBookmarksSynchronizer: XCTestCase {
    func testBuildMobileRootAndChildrenRecords_noMobileRootInBuffer() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let buffer = MockBuffer()
        let storage = MockStorage()
        storage.local[BookmarkRoots.MobileFolderGUID] = BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: nil, title: "Mobile Bookmarks", description: nil, children: ["bk1"])
        storage.local["bk1"] = BookmarkMirrorItem.bookmark("bk1", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 1", description: nil, URI: "https://example.com/1", tags: "", keyword: nil)
        storage.local["bk1"] = BookmarkMirrorItem.bookmark("bk1", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 1", description: nil, URI: "https://example.com/1", tags: "", keyword: nil)
        let bk2 = BookmarkMirrorItem.bookmark("bk2", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 2", description: nil, URI: "https://example.com/2", tags: "", keyword: nil)
        let bk3 = BookmarkMirrorItem.bookmark("bk3", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 3", description: nil, URI: "https://example.com/3", tags: "", keyword: nil)
        storage.local["bk2"] = bk2
        storage.local["bk3"] = bk3

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        let (mobileRootRecord, childrenRecords) = synchronizer.buildMobileRootAndChildrenRecords(storage, buffer, additionalChildren: [bk2, bk3]).value.successValue!
        XCTAssertEqual(mobileRootRecord.id, BookmarkRoots.translateOutgoingRootGUID(BookmarkRoots.MobileFolderGUID))
        XCTAssertEqual(mobileRootRecord.payload.json["title"], "Mobile Bookmarks")
        // We are not including bk1 in the call to buildMobileRootRecord() therefore it should NOT be included in the returned record
        XCTAssertEqual(mobileRootRecord.payload.json["children"], ["bk2", "bk3"])

        XCTAssertEqual(childrenRecords.count, 2)
        XCTAssertEqual(childrenRecords[0].id, "bk2")
        XCTAssertEqual(childrenRecords[1].id, "bk3")
    }

    func testBuildMobileRootAndChildrenRecords_mobileRootInBuffer() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let buffer = MockBuffer()
        buffer.buffer[BookmarkRoots.MobileFolderGUID] = BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: nil, title: "Mobile Bookmarks", description: nil, children: ["bk1"])
        buffer.children[BookmarkRoots.MobileFolderGUID] = ["bk1"]
        buffer.buffer["bk1"] = BookmarkMirrorItem.bookmark("bk1", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 1", description: nil, URI: "https://example.com/1", tags: "", keyword: nil)

        let storage = MockStorage()
        storage.local["bk1"] = BookmarkMirrorItem.bookmark("bk1", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 1", description: nil, URI: "https://example.com/1", tags: "", keyword: nil)
        let bk2 = BookmarkMirrorItem.bookmark("bk2", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 2", description: nil, URI: "https://example.com/2", tags: "", keyword: nil)
        let bk3 = BookmarkMirrorItem.bookmark("bk3", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "Bookmark 3", description: nil, URI: "https://example.com/3", tags: "", keyword: nil)
        storage.local["bk2"] = bk2
        storage.local["bk3"] = bk3

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        let (mobileRootRecord, childrenRecords) = synchronizer.buildMobileRootAndChildrenRecords(storage, buffer, additionalChildren: [bk2, bk3]).value.successValue!
        XCTAssertEqual(mobileRootRecord.id, BookmarkRoots.translateOutgoingRootGUID(BookmarkRoots.MobileFolderGUID))
        XCTAssertEqual(mobileRootRecord.payload.json["title"], "Mobile Bookmarks")
        // bk1 is a children of mobile root in the buffer, therefore it should be included here.
        XCTAssertEqual(mobileRootRecord.payload.json["children"], ["bk1", "bk2", "bk3"])

        // We are only sending the new records though!
        XCTAssertEqual(childrenRecords.count, 2)
        XCTAssertEqual(childrenRecords[0].id, "bk2")
        XCTAssertEqual(childrenRecords[1].id, "bk3")
    }

    func testUploadSomeLocalRecords_batched_ok() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let records = createMobileRootAndChildrenRecords(numChildren: 80)

        var numPosts = 0
        let now = Date.now()
        var firstPostLastModified: Timestamp?
        var secondPostLastModified: Timestamp?
        let uploader: BatchUploadFunction = { lines, ifUnmodifiedSince, queryParams in
            numPosts += 1
            var headers = [String: Any]()

            let result: POSTResult
            if numPosts == 1 {
                result = POSTResult(success: records.childrenRecords.map { $0.id } + ["mobile"], failed: [:], batchToken: "toktok")
                firstPostLastModified = now
                headers["X-Last-Modified"] = firstPostLastModified
            } else {
                XCTAssertEqual(queryParams![0].name, "batch")
                XCTAssertEqual(queryParams![0].value, "toktok")
                XCTAssertEqual(queryParams![1].name, "commit")
                XCTAssertEqual(queryParams![1].value, "true")
                result = POSTResult(success: [], failed: [:])
                secondPostLastModified = now + 5000
                headers["X-Last-Modified"] = secondPostLastModified
            }
            let response = StorageResponse<POSTResult>(value: result, metadata: ResponseMetadata(status: 200, headers: headers))
            return deferMaybe(response)
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 1_048_576, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).succeeded()
        XCTAssertEqual(storage.lastBufferUpdatedCompletionOpApplied?.bufferValuesToMoveFromLocal.count, 81)
        XCTAssertEqual(numPosts, 2)
        XCTAssertEqual(mirrorer.lastModified / 1000, secondPostLastModified)
    }

    func testUploadSomeLocalRecords_batched_someFailed() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let records = createMobileRootAndChildrenRecords(numChildren: 80)

        var numPosts = 0
        let uploader: BatchUploadFunction = { lines, ifUnmodifiedSince, queryParams in
            numPosts += 1
            var headers = [String: Any]()
            headers["X-Last-Modified"] = Date.now()

            let result = POSTResult(success: records.childrenRecords.map { $0.id }.dropFirst(20) + ["mobile"], failed: [:], batchToken: "toktok")
            let response = StorageResponse<POSTResult>(value: result, metadata: ResponseMetadata(status: 200, headers: headers))
            return deferMaybe(response)
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 1_048_576, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        let error = synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).value.failureValue!
        XCTAssertTrue(error is RecordsFailedToUpload)
        XCTAssertNil(storage.lastBufferUpdatedCompletionOpApplied)
        XCTAssertEqual(numPosts, 1)
    }

    func testUploadSomeLocalRecords_nobatch_ok() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let records = createMobileRootAndChildrenRecords(numChildren: 80)

        var numPosts = 0
        let uploader: BatchUploadFunction = { lines, ifUnmodifiedSince, queryParams in
            numPosts += 1
            var headers = [String: Any]()
            headers["X-Last-Modified"] = Date.now()

            let result = POSTResult(success: records.childrenRecords.map { $0.id } + ["mobile"], failed: [:])
            let response = StorageResponse<POSTResult>(value: result, metadata: ResponseMetadata(status: 200, headers: headers))
            return deferMaybe(response)
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 1_048_576, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).succeeded()
        XCTAssertEqual(storage.lastBufferUpdatedCompletionOpApplied?.bufferValuesToMoveFromLocal.count, 81)
        XCTAssertEqual(numPosts, 1)
    }

    func testUploadSomeLocalRecords_nobatch_someFailed() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let records = createMobileRootAndChildrenRecords(numChildren: 80)

        var numPosts = 0
        let uploader: BatchUploadFunction = { lines, ifUnmodifiedSince, queryParams in
            numPosts += 1
            var headers = [String: Any]()
            headers["X-Last-Modified"] = Date.now()

            let result = POSTResult(success: records.childrenRecords.map { $0.id }.dropFirst(20) + ["mobile"], failed: [:])
            let response = StorageResponse<POSTResult>(value: result, metadata: ResponseMetadata(status: 200, headers: headers))
            return deferMaybe(response)
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 1_048_576, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).succeeded()
        XCTAssertEqual(storage.lastBufferUpdatedCompletionOpApplied?.bufferValuesToMoveFromLocal.count, 61)
        XCTAssertEqual(numPosts, 1)
    }

    func testUploadSomeLocalRecords_tooManyRecords() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let uploader: BatchUploadFunction = { _, _, _ in
            // Should never happen
            XCTFail()
            return deferMaybe(NSError())
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 1_048_576, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let records = createMobileRootAndChildrenRecords(numChildren: 120)

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        let error = synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).value.failureValue!
        XCTAssertTrue(error is TooManyRecordsError)
    }

    func testUploadSomeLocalRecords_tooBig() {
        let delegate = MockSyncDelegate()
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let storage = MockStorage()
        let buffer = MockBuffer()

        let uploader: BatchUploadFunction = { _, _, _ in
            // Should never happen
            XCTFail()
            return deferMaybe(NSError())
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 100, maxPostBytes: 5000, maxTotalRecords: 250, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "bookmarks", encrypter: getBookmarksEncrypter())
        let mirrorer = BookmarksMirrorer(storage: buffer, client: collectionClient, basePrefs: prefs, collection: "bookmarks", statsSession: SyncEngineStatsSession(collection: "bookmarks"))

        let records = createMobileRootAndChildrenRecords(numChildren: 80)

        let synchronizer = BufferingBookmarksSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, why: .scheduled)
        let error = synchronizer.uploadSomeLocalRecords(storage, mirrorer, collectionClient, mobileRootRecord: records.mobileRootRecord, childrenRecords: records.childrenRecords).value.failureValue!
        XCTAssertTrue(error is TooManyRecordsError)
    }

    func getBookmarksEncrypter() -> RecordEncrypter<BookmarkBasePayload> {
        let serializer: (Record<BookmarkBasePayload>) -> JSON? = { $0.payload.json }
        let factory: (String) -> BookmarkBasePayload = { BookmarkBasePayload($0) }
        return RecordEncrypter(serializer: serializer, factory: factory)
    }

    func createMobileRootAndChildrenRecords(numChildren: Int) -> (mobileRootRecord: Record<BookmarkBasePayload>, childrenRecords: [Record<BookmarkBasePayload>]) {
        var childrenRecords: [Record<BookmarkBasePayload>] = []
        for i in 0...numChildren {
            let item = BookmarkMirrorItem.bookmark("bk1\(i)", modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.MobileFolderGUID, parentName: nil, title: "bk1\(i)", description: nil, URI: "https://example.com/\(i)", tags: "", keyword: nil)
            let record = Record<BookmarkBasePayload>(id: item.guid, payload: item.asPayload())
            childrenRecords.append(record)
        }
        let mobileRoot = BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: Date.now(), hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: nil, title: "Mobile Bookmarks", description: nil, children: [])
        let mobileRootRecord = Record<BookmarkBasePayload>(id: BookmarkRoots.translateOutgoingRootGUID(BookmarkRoots.MobileFolderGUID), payload: mobileRoot.asPayloadWithChildren(childrenRecords.map { $0.id }))

        return (mobileRootRecord: mobileRootRecord, childrenRecords: childrenRecords)
    }
}
