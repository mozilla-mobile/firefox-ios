/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Deferred
import Foundation
import Shared
@testable import Storage
@testable import Sync
import XCTest

extension Dictionary {
    init<S: SequenceType where S.Generator.Element == Element>(seq: S) {
        self.init()
        for (k, v) in seq {
            self[k] = v
        }
    }
}

class MockLocalItemSource: LocalItemSource {
    var local: [GUID: BookmarkMirrorItem] = [:]

    func getLocalItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        guard let item = self.local[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find item \(guid)."))
        }
        return deferMaybe(item)
    }

    func getLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        var acc: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach { guid in
            if let item = self.local[guid] {
                acc[guid] = item
            }
        }
        return deferMaybe(acc)
    }

    func prefetchLocalItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        return succeed()
    }
}

class MockMirrorItemSource: MirrorItemSource {
    var mirror: [GUID: BookmarkMirrorItem] = [:]

    func getMirrorItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        guard let item = self.mirror[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find item \(guid)."))
        }
        return deferMaybe(item)
    }

    func getMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        var acc: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach { guid in
            if let item = self.mirror[guid] {
                acc[guid] = item
            }
        }
        return deferMaybe(acc)
    }

    func prefetchMirrorItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        return succeed()
    }
}

class MockBufferItemSource: BufferItemSource {
    var buffer: [GUID: BookmarkMirrorItem] = [:]

    func getBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Deferred<Maybe<[GUID: BookmarkMirrorItem]>> {
        var acc: [GUID: BookmarkMirrorItem] = [:]
        guids.forEach { guid in
            if let item = self.buffer[guid] {
                acc[guid] = item
            }
        }
        return deferMaybe(acc)
    }

    func getBufferItemWithGUID(guid: GUID) -> Deferred<Maybe<BookmarkMirrorItem>> {
        guard let item = self.buffer[guid] else {
            return deferMaybe(DatabaseError(description: "Couldn't find item \(guid)."))
        }
        return deferMaybe(item)
    }

    func prefetchBufferItemsWithGUIDs<T: CollectionType where T.Generator.Element == GUID>(guids: T) -> Success {
        return succeed()
    }
}

class MockUploader {
    var deletions: Set<GUID> = Set<GUID>()
    var added: Set<GUID> = Set<GUID>()
    var records: [GUID: Record<BookmarkBasePayload>] = [:]

    func getStorer() -> TrivialBookmarkStorer {
        return TrivialBookmarkStorer(uploader: self.doUpload)
    }

    func doUpload(recs: [Record<BookmarkBasePayload>], lastTimestamp: Timestamp?, onUpload: (POSTResult) -> DeferredTimestamp) -> DeferredTimestamp {
        var success: [GUID] = []
        recs.forEach { rec in
            success.append(rec.id)
            self.records[rec.id] = rec
            if rec.payload.deleted {
                self.deletions.insert(rec.id)
            } else {
                self.added.insert(rec.id)
            }
        }

        // Now pretend we did the upload.
        return onUpload(POSTResult(modified: NSDate.now(), success: success, failed: [:]))
    }
}

// Thieved mercilessly from TestSQLiteBookmarks.
private func getBrowserDBForFile(filename: String, files: FileAccessor) -> BrowserDB? {
    let db = BrowserDB(filename: filename, files: files)

    // BrowserTable exists only to perform create/update etc. operations -- it's not
    // a queryable thing that needs to stick around.
    if !db.createOrUpdate(BrowserTable()) {
        return nil
    }
    return db
}

class FailFastTestCase: XCTestCase {
    // This is how to make an assertion failure stop the current test function
    // but continue with other test functions in the same test case.
    // See http://stackoverflow.com/a/27016786/22003
    override func invokeTest() {
        self.continueAfterFailure = false
        defer { self.continueAfterFailure = true }
        super.invokeTest()
    }
}

class TestBookmarkTreeMerging: FailFastTestCase {
    let files = MockFiles()

    override func tearDown() {
        do {
            try self.files.removeFilesInDirectory()
        } catch {
        }
        super.tearDown()
    }

    private func getBrowserDB(name: String) -> BrowserDB? {
        let file = "TBookmarkTreeMerging\(name).db"
        return getBrowserDBForFile(file, files: self.files)
    }

    func getSyncableBookmarks(name: String) -> MergedSQLiteBookmarks? {
        guard let db = self.getBrowserDB(name) else {
            XCTFail("Couldn't get prepared DB.")
            return nil
        }

        return MergedSQLiteBookmarks(db: db)
    }

    func getSQLiteBookmarks(name: String) -> SQLiteBookmarks? {
        guard let db = self.getBrowserDB(name) else {
            XCTFail("Couldn't get prepared DB.")
            return nil
        }

        return SQLiteBookmarks(db: db)
    }

    func dbLocalTree(name: String) -> BookmarkTree? {
        guard let bookmarks = self.getSQLiteBookmarks(name) else {
            XCTFail("Couldn't get bookmarks.")
            return nil
        }

        return bookmarks.treeForLocal().value.successValue
    }

    func localTree() -> BookmarkTree {
        let roots = BookmarkRoots.RootChildren.map { BookmarkTreeNode.Folder(guid: $0, children: []) }
        let places = BookmarkTreeNode.Folder(guid: BookmarkRoots.RootGUID, children: roots)

        var lookup: [GUID: BookmarkTreeNode] = [:]
        var parents: [GUID: GUID] = [:]

        for n in roots {
            lookup[n.recordGUID] = n
            parents[n.recordGUID] = BookmarkRoots.RootGUID
        }
        lookup[BookmarkRoots.RootGUID] = places

        return BookmarkTree(subtrees: [places], lookup: lookup, parents: parents, orphans: Set(), deleted: Set(), modified: Set(lookup.keys), virtual: Set())
    }

    // Our synthesized tree is the same as the one we pull out of a brand new local DB.
    func testLocalTreeAssumption() {
        let constructed = self.localTree()
        let fromDB = self.dbLocalTree("A")
        XCTAssertNotNil(fromDB)
        XCTAssertTrue(fromDB!.isFullyRootedIn(constructed))
        XCTAssertTrue(constructed.isFullyRootedIn(fromDB!))
        XCTAssertTrue(fromDB!.virtual.isEmpty)
        XCTAssertTrue(constructed.virtual.isEmpty)
    }

    // This should never occur in the wild: local will never be empty.
    func testMergingEmpty() {
        let r = BookmarkTree.emptyTree()
        let m = BookmarkTree.emptyMirrorTree()
        let l = BookmarkTree.emptyTree()
        let s = ItemSources(local: MockLocalItemSource(), mirror: MockMirrorItemSource(), buffer: MockBufferItemSource())

        XCTAssertEqual(m.virtual, BookmarkRoots.Real)
        let merger = ThreeWayTreeMerger(local: l, mirror: m, remote: r, itemSources: s)
        guard let mergedTree = merger.produceMergedTree().value.successValue else {
            XCTFail("Couldn't merge.")
            return
        }

        mergedTree.dump()
        XCTAssertEqual(mergedTree.allGUIDs, BookmarkRoots.Real)

        guard let result = merger.produceMergeResultFromMergedTree(mergedTree).value.successValue else {
            XCTFail("Couldn't produce result.")
            return
        }

        // We don't test the local override completion, because of course we saw mirror items.
        XCTAssertTrue(result.uploadCompletion.isNoOp)
        XCTAssertTrue(result.bufferCompletion.isNoOp)
    }

    func getItemSourceIncludingEmptyRoots() -> ItemSources {
        let local = MockLocalItemSource()

        func makeRoot(guid: GUID, _ name: String) {
            local.local[guid] = BookmarkMirrorItem.folder(guid, modified: NSDate.now(), hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: name, description: nil, children: [])
        }

        makeRoot(BookmarkRoots.MenuFolderGUID, "Bookmarks Menu")
        makeRoot(BookmarkRoots.ToolbarFolderGUID, "Bookmarks Toolbar")
        makeRoot(BookmarkRoots.MobileFolderGUID, "Mobile Bookmarks")
        makeRoot(BookmarkRoots.UnfiledFolderGUID, "Unsorted Bookmarks")
        makeRoot(BookmarkRoots.RootGUID, "")

        return ItemSources(local: local, mirror: MockMirrorItemSource(), buffer: MockBufferItemSource())
    }

    func testMergingOnlyLocalRoots() {
        let r = BookmarkTree.emptyTree()
        let m = BookmarkTree.emptyMirrorTree()
        let l = self.localTree()
        let s = self.getItemSourceIncludingEmptyRoots()

        let merger = ThreeWayTreeMerger(local: l, mirror: m, remote: r, itemSources: s)
        guard let mergedTree = merger.produceMergedTree().value.successValue else {
            XCTFail("Couldn't merge.")
            return
        }

        mergedTree.dump()
        XCTAssertEqual(mergedTree.allGUIDs, BookmarkRoots.Real)

        guard let result = merger.produceMergeResultFromMergedTree(mergedTree).value.successValue else {
            XCTFail("Couldn't produce result.")
            return
        }

        XCTAssertFalse(result.isNoOp)
        XCTAssertTrue(result.overrideCompletion.processedLocalChanges.isSupersetOf(Set(BookmarkRoots.RootChildren)))

        // We should be dropping the roots from local, and uploading roots to the server.
        // The outgoing records should use Sync-style IDs.
        // We never upload the places root.
        let banned = Set<GUID>(["places", BookmarkRoots.RootGUID])
        XCTAssertTrue(banned.isDisjointWith(result.uploadCompletion.records.map { $0.id }))
        XCTAssertTrue(banned.isDisjointWith(result.uploadCompletion.amendChildrenFromBuffer.keys))
        XCTAssertTrue(banned.isDisjointWith(result.uploadCompletion.amendChildrenFromMirror.keys))
        XCTAssertTrue(banned.isDisjointWith(result.uploadCompletion.amendChildrenFromLocal.keys))
        XCTAssertEqual(Set(BookmarkRoots.RootChildren), Set(result.uploadCompletion.amendChildrenFromLocal.keys))
        XCTAssertEqual(Set(BookmarkRoots.Real), result.overrideCompletion.processedLocalChanges)
    }

    func testMergingInconsistentBufferWithMissingValues() {
        guard let bookmarks = self.getSyncableBookmarks("H") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Setup a buffer with a folder that points to a bookmark but doesn't actually contain said bookmark.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.folder("folderA", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "folderA", description: nil, children: ["bookmarkA"])
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        let result = applier.go()
        result.failed()
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        XCTAssertEqual(result.value.failureValue!.description, BufferInconsistency.MissingValues.description)

        // Buffer should remain in the busted state and not clear.
        XCTAssertFalse(bookmarks.isEmpty().value.successValue!)
    }

    func testMergingInconsistentBufferWithMissingStructure() {
        guard let bookmarks = self.getSyncableBookmarks("I") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set up the buffer with a bookmark and a folder but the bookmark is parentless to simulate missing structure.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.bookmark("bookmarkA", modified: bufferDate, hasDupe: false, parentID: "", parentName: "", title: "F", description: nil, URI: "http://example.com/f", tags: "", keyword: nil),
            BookmarkMirrorItem.folder("folderB", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "folderB", description: nil, children: [])
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })

        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        let result = applier.go()
        result.failed()
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        XCTAssertEqual(result.value.failureValue!.description, BufferInconsistency.MissingStructure.description)

        // Buffer should remain in the busted state and not clear.
        XCTAssertFalse(bookmarks.isEmpty().value.successValue!)
    }

    func testMergingInconsistentBufferWithParentIDDisagreement() {
        guard let bookmarks = self.getSyncableBookmarks("I") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set up the buffer with a bookmark that lives in two folders.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.bookmark("bookmarkA", modified: bufferDate, hasDupe: false, parentID: "folderB", parentName: "", title: "F", description: nil, URI: "http://example.com/f", tags: "", keyword: nil),
            BookmarkMirrorItem.folder("folderA", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "folderA", description: nil, children: ["bookmarkA"])
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        let result = applier.go()
        result.failed()
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        XCTAssertEqual(result.value.failureValue!.description, BufferInconsistency.ParentIDDisagreement.description)

        // Buffer should remain in the busted state and not clear.
        XCTAssertFalse(bookmarks.isEmpty().value.successValue!)
    }

    func testMergingInconsistentBufferWithOverlappingStructure() {
        guard let bookmarks = self.getSyncableBookmarks("I") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set up the buffer with a bookmark that lives in two folders.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.bookmark("bookmarkA", modified: bufferDate, hasDupe: false, parentID: "", parentName: "", title: "F", description: nil, URI: "http://example.com/f", tags: "", keyword: nil),
            BookmarkMirrorItem.folder("folderA", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "folderA", description: nil, children: ["bookmarkA"]),
            BookmarkMirrorItem.folder("folderB", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "folderB", description: nil, children: ["bookmarkA"])
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        let result = applier.go()
        result.failed()
        XCTAssertEqual(bookmarks.bufferState().value.successValue!, BookmarkBufferState.UnmergedRemoteChanges)
        XCTAssertEqual(result.value.failureValue!.description, BufferInconsistency.OverlappingStructure.description)

        // Buffer should remain in the busted state and not clear.
        XCTAssertFalse(bookmarks.isEmpty().value.successValue!)
    }

    func testMergingStorageLocalRootsEmptyServer() {
        guard let bookmarks = self.getSyncableBookmarks("B") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // The mirror is never actually empty.
        let mirrorTree = bookmarks.treeForMirror().value.successValue!
        XCTAssertFalse(mirrorTree.isEmpty)
        XCTAssertEqual(mirrorTree.lookup.keys.count, 5)   // Root and four children.
        XCTAssertEqual(1, mirrorTree.subtrees.count)

        let edgesBefore = bookmarks.treesForEdges().value.successValue!
        XCTAssertFalse(edgesBefore.local.isEmpty)
        XCTAssertTrue(edgesBefore.buffer.isEmpty)

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        applier.go().succeeded()

        // Now the local contents are replicated into the mirror, and both the buffer and local are empty.
        guard let mirror = bookmarks.treeForMirror().value.successValue else {
            XCTFail("Couldn't get mirror!")
            return
        }

        XCTAssertFalse(mirror.isEmpty)
        XCTAssertTrue(mirror.subtrees[0].recordGUID == BookmarkRoots.RootGUID)
        let edgesAfter = bookmarks.treesForEdges().value.successValue!
        XCTAssertTrue(edgesAfter.local.isEmpty)
        XCTAssertTrue(edgesAfter.buffer.isEmpty)

        XCTAssertEqual(uploader.added, Set(BookmarkRoots.RootChildren.map(BookmarkRoots.translateOutgoingRootGUID)))
    }

    func testComplexOrphaning() {
        // This test describes a scenario like this:
        //
        //         []                []                   []
        //      [M]  [T]          [M]  [T]             [M]  [T]
        //       |    |            |    |               |    |
        //      [C]  [A]          [C]  [A]             [C]  [A]
        //       |                 |    |                    |
        //      [D]               [D]  [B]                  [B]
        //       |                                           |
        //       F                                           E
        //
        // That is: we have locally added 'E' to folder B and deleted folder D,
        // and remotely added 'F' to folder D and deleted folder B.
        //
        // This is a fundamental conflict that would ordinarily produce orphans.
        // Our resolution for this is to put those orphans _somewhere_.
        //
        // That place is the lowest surviving parent: walk the tree until we find
        // a folder that still exists, and put the orphans there. This is a little
        // better than just dumping the records into Unsorted Bookmarks, and no
        // more complex than dumping them into the closest root.
        //
        // We expect:
        //
        //         []
        //      [M]  [T]
        //       |    |
        //      [C]  [A]
        //       |    |
        //       F    E
        //
        guard let bookmarks = self.getSyncableBookmarks("G") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set up the mirror.
        let mirrorDate = NSDate.now() - 100000
        let records = [
            BookmarkMirrorItem.folder(BookmarkRoots.RootGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "", description: "", children: BookmarkRoots.RootChildren),
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["folderCCCCCC"]),
            BookmarkMirrorItem.folder(BookmarkRoots.UnfiledFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Unsorted Bookmarks", description: "", children: []),
            BookmarkMirrorItem.folder(BookmarkRoots.ToolbarFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Toolbar", description: "", children: ["folderAAAAAA"]),
            BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Mobile Bookmarks", description: "", children: []),
            BookmarkMirrorItem.folder("folderAAAAAA", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "A", description: "", children: ["folderBBBBBB"]),
            BookmarkMirrorItem.folder("folderBBBBBB", modified: mirrorDate, hasDupe: false, parentID: "folderAAAAAA", parentName: "A", title: "B", description: "", children: []),
            BookmarkMirrorItem.folder("folderCCCCCC", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "C", description: "", children: ["folderDDDDDD"]),
            BookmarkMirrorItem.folder("folderDDDDDD", modified: mirrorDate, hasDupe: false, parentID: "folderCCCCCC", parentName: "C", title: "D", description: "", children: []),
        ]

        bookmarks.populateMirrorViaBuffer(records, atDate: mirrorDate)
        bookmarks.wipeLocal()

        // Now the buffer is empty, and the mirror tree is what we expect.
        let mirrorTree = bookmarks.treeForMirror().value.successValue!
        XCTAssertFalse(mirrorTree.isEmpty)

        XCTAssertEqual(mirrorTree.lookup.keys.count, 9)
        XCTAssertEqual(1, mirrorTree.subtrees.count)
        XCTAssertEqual(mirrorTree.find("folderAAAAAA")!.children!.map { $0.recordGUID }, ["folderBBBBBB"])
        XCTAssertEqual(mirrorTree.find("folderCCCCCC")!.children!.map { $0.recordGUID }, ["folderDDDDDD"])

        let edgesBefore = bookmarks.treesForEdges().value.successValue!
        XCTAssertTrue(edgesBefore.local.isEmpty)      // Because we're fully synced.
        XCTAssertTrue(edgesBefore.buffer.isEmpty)

        // Set up the buffer.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.deleted(BookmarkNodeType.Folder, guid: "folderBBBBBB", modified: bufferDate),
            BookmarkMirrorItem.folder("folderAAAAAA", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "A", description: "", children: []),
            BookmarkMirrorItem.folder("folderDDDDDD", modified: bufferDate, hasDupe: false, parentID: "folderCCCCCC", parentName: "C", title: "D", description: "", children: ["bookmarkFFFF"]),
            BookmarkMirrorItem.bookmark("bookmarkFFFF", modified: bufferDate, hasDupe: false, parentID: "folderDDDDDD", parentName: "D", title: "F", description: nil, URI: "http://example.com/f", tags: "", keyword: nil),
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()

        // Make local changes.
        bookmarks.local.modelFactory.value.successValue!.removeByGUID("folderDDDDDD").succeeded()
        bookmarks.local.insertBookmark("http://example.com/e".asURL!, title: "E", favicon: nil, intoFolder: "folderBBBBBB", withTitle: "B").succeeded()
        let insertedGUID = bookmarks.local.db.getGUIDs("SELECT guid FROM \(TableBookmarksLocal) WHERE title IS 'E'")[0]

        let edges = bookmarks.treesForEdges().value.successValue!

        XCTAssertFalse(edges.local.isEmpty)
        XCTAssertFalse(edges.buffer.isEmpty)
        XCTAssertTrue(edges.local.isFullyRootedIn(mirrorTree))
        XCTAssertTrue(edges.buffer.isFullyRootedIn(mirrorTree))
        XCTAssertTrue(edges.buffer.deleted.contains("folderBBBBBB"))
        XCTAssertFalse(edges.buffer.deleted.contains("folderDDDDDD"))
        XCTAssertFalse(edges.local.deleted.contains("folderBBBBBB"))
        XCTAssertTrue(edges.local.deleted.contains("folderDDDDDD"))

        // Now merge.
        let storageMerger = ThreeWayBookmarksStorageMerger(buffer: bookmarks, storage: bookmarks)
        let merger = storageMerger.getMerger().value.successValue!
        guard let mergedTree = merger.produceMergedTree().value.successValue else {
            XCTFail("Couldn't get merge result.")
            return
        }

        // Dump it so we can see it.
        mergedTree.dump()

        XCTAssertTrue(mergedTree.deleteLocally.contains("folderBBBBBB"))
        XCTAssertTrue(mergedTree.deleteFromMirror.contains("folderBBBBBB"))
        XCTAssertTrue(mergedTree.deleteRemotely.contains("folderDDDDDD"))
        XCTAssertTrue(mergedTree.deleteFromMirror.contains("folderDDDDDD"))
        XCTAssertTrue(mergedTree.acceptLocalDeletion.contains("folderDDDDDD"))
        XCTAssertTrue(mergedTree.acceptRemoteDeletion.contains("folderBBBBBB"))

        // E and F still exist, in Menu and Toolbar respectively.
        // Note that the merge itself includes asserts for this; we shouldn't even get here if
        // this part will fail.
        XCTAssertTrue(mergedTree.allGUIDs.contains(insertedGUID))
        XCTAssertTrue(mergedTree.allGUIDs.contains("bookmarkFFFF"))

        let menu = mergedTree.root.mergedChildren![0]   // menu, toolbar, unfiled, mobile, so 0.
        let toolbar = mergedTree.root.mergedChildren![1]   // menu, toolbar, unfiled, mobile, so 1.
        XCTAssertEqual(BookmarkRoots.MenuFolderGUID, menu.guid)
        XCTAssertEqual(BookmarkRoots.ToolbarFolderGUID, toolbar.guid)

        let folderC = menu.mergedChildren![0]
        let folderA = toolbar.mergedChildren![0]
        XCTAssertEqual("folderCCCCCC", folderC.guid)
        XCTAssertEqual("folderAAAAAA", folderA.guid)

        XCTAssertEqual(insertedGUID, folderA.mergedChildren![0].guid)
        XCTAssertEqual("bookmarkFFFF", folderC.mergedChildren![0].guid)

        guard let result = merger.produceMergeResultFromMergedTree(mergedTree).value.successValue else {
            XCTFail("Couldn't get merge result.")
            return
        }

        XCTAssertFalse(result.isNoOp)

        // Everything in local is getting dropped.
        let formerLocalIDs = Set(edges.local.lookup.keys)
        XCTAssertTrue(result.overrideCompletion.processedLocalChanges.isSupersetOf(formerLocalIDs))

        // Everything in the buffer is getting dropped.
        let formerBufferIDs = Set(edges.buffer.lookup.keys)
        XCTAssertTrue(result.bufferCompletion.processedBufferChanges.isSupersetOf(formerBufferIDs))

        // The mirror will now contain everything added by each side, and not the deleted folders.
        XCTAssertEqual(result.overrideCompletion.mirrorItemsToDelete, Set(["folderBBBBBB", "folderDDDDDD"]))
        XCTAssertTrue(result.overrideCompletion.mirrorValuesToCopyFromLocal.isEmpty)
        XCTAssertTrue(result.overrideCompletion.mirrorValuesToCopyFromBuffer.isEmpty)
        XCTAssertTrue(result.overrideCompletion.mirrorItemsToInsert.keys.contains(insertedGUID))   // Because it was reparented.
        XCTAssertTrue(result.overrideCompletion.mirrorItemsToInsert.keys.contains("bookmarkFFFF"))   // Because it was reparented.

        // The mirror now has the right structure.
        XCTAssertEqual(result.overrideCompletion.mirrorStructures["folderCCCCCC"]!, ["bookmarkFFFF"])
        XCTAssertEqual(result.overrideCompletion.mirrorStructures["folderAAAAAA"]!, [insertedGUID])

        // We're going to upload new records for C (lost a child), F (changed parent),
        // insertedGUID (new local record), A (new child), and D (deleted).

        // Anything that was in the mirror and only changed structure:
        XCTAssertEqual(result.uploadCompletion.amendChildrenFromMirror, ["folderCCCCCC": ["bookmarkFFFF"], "folderAAAAAA": [insertedGUID]])

        // Anything deleted:
        XCTAssertTrue(result.uploadCompletion.records.contains { ($0.id == "folderDDDDDD") && ($0.payload["deleted"].asBool ?? false) })

        // Inserted:
        let uploadE = result.uploadCompletion.records.find { $0.id == insertedGUID }
        XCTAssertNotNil(uploadE)
        XCTAssertEqual(uploadE!.payload["title"].asString!, "E")

        // We fixed the parent before uploading.
        XCTAssertEqual(uploadE!.payload["parentid"].asString!, "folderAAAAAA")
        XCTAssertEqual(uploadE!.payload["parentName"].asString ?? "", "A")

        // Reparented:
        let uploadF = result.uploadCompletion.records.find { $0.id == "bookmarkFFFF" }
        XCTAssertNotNil(uploadF)
        XCTAssertEqual(uploadF!.payload["title"].asString!, "F")

        // We fixed the parent before uploading.
        XCTAssertEqual(uploadF!.payload["parentid"].asString!, "folderCCCCCC")
        XCTAssertEqual(uploadF!.payload["parentName"].asString ?? "", "C")
    }

    func testComplexMoveWithAdditions() {
        // This test describes a scenario like this:
        //
        //         []                []                   []
        //      [X]  [Y]          [X]  [Y]             [X]  [Y]
        //       |    |                 |                    |
        //      [A]   C                [A]                  [A]
        //     /   \                  /   \                / | \
        //    B     E                B     C              B  D  C
        //
        // That is: we have locally added 'D' to folder A, and remotely moved
        // A to a different root, added 'E', and moved 'C' back to the old root.
        //
        // Our expected result is:
        //
        //        []
        //     [X]  [Y]
        //      |    |
        //     [A]   C
        //    / | \
        //   B  D  E
        //
        // … but we'll settle for any order of children for [A] that preserves B < E
        // and B < D -- in other words, (B E D) and (B D E) are both acceptable.
        //
        guard let bookmarks = self.getSyncableBookmarks("F") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Set up the mirror.
        let mirrorDate = NSDate.now() - 100000
        let records = [
            BookmarkMirrorItem.folder(BookmarkRoots.RootGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "", description: "", children: BookmarkRoots.RootChildren),
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["folderAAAAAA"]),
            BookmarkMirrorItem.folder(BookmarkRoots.UnfiledFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Unsorted Bookmarks", description: "", children: []),
            BookmarkMirrorItem.folder(BookmarkRoots.ToolbarFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Toolbar", description: "", children: []),
            BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Mobile Bookmarks", description: "", children: []),
            BookmarkMirrorItem.folder("folderAAAAAA", modified: mirrorDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "Bookmarks Menu", title: "A", description: "", children: ["bookmarkBBBB", "bookmarkCCCC"]),
            BookmarkMirrorItem.bookmark("bookmarkBBBB", modified: mirrorDate, hasDupe: false, parentID: "folderAAAAAA", parentName: "A", title: "B", description: nil, URI: "http://example.com/b", tags: "", keyword: nil),
            BookmarkMirrorItem.bookmark("bookmarkCCCC", modified: mirrorDate, hasDupe: false, parentID: "folderAAAAAA", parentName: "A", title: "C", description: nil, URI: "http://example.com/c", tags: "", keyword: nil),
        ]

        bookmarks.populateMirrorViaBuffer(records, atDate: mirrorDate)
        bookmarks.wipeLocal()

        // Now the buffer is empty, and the mirror tree is what we expect.
        let mirrorTree = bookmarks.treeForMirror().value.successValue!
        XCTAssertFalse(mirrorTree.isEmpty)

        XCTAssertEqual(mirrorTree.lookup.keys.count, 8)
        XCTAssertEqual(1, mirrorTree.subtrees.count)
        XCTAssertEqual(mirrorTree.find("folderAAAAAA")!.children!.map { $0.recordGUID }, ["bookmarkBBBB", "bookmarkCCCC"])

        let edgesBefore = bookmarks.treesForEdges().value.successValue!
        XCTAssertTrue(edgesBefore.local.isEmpty)        // Because we're fully synced.
        XCTAssertTrue(edgesBefore.buffer.isEmpty)

        // Set up the buffer.
        let bufferDate = NSDate.now()
        let changedBufferRecords = [
            BookmarkMirrorItem.folder(BookmarkRoots.MenuFolderGUID, modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Menu", description: "", children: ["bookmarkCCCC"]),
            BookmarkMirrorItem.folder(BookmarkRoots.ToolbarFolderGUID, modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Bookmarks Toolbar", description: "", children: ["folderAAAAAA"]),
            BookmarkMirrorItem.folder("folderAAAAAA", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.ToolbarFolderGUID, parentName: "Bookmarks Toolbar", title: "A", description: "", children: ["bookmarkBBBB", "bookmarkEEEE"]),
            BookmarkMirrorItem.bookmark("bookmarkCCCC", modified: bufferDate, hasDupe: false, parentID: BookmarkRoots.MenuFolderGUID, parentName: "A", title: "C", description: nil, URI: "http://example.com/c", tags: "", keyword: nil),
            BookmarkMirrorItem.bookmark("bookmarkEEEE", modified: bufferDate, hasDupe: false, parentID: "folderAAAAAA", parentName: "A", title: "E", description: nil, URI: "http://example.com/e", tags: "", keyword: nil),
        ]

        bookmarks.applyRecords(changedBufferRecords).succeeded()
        let populatedBufferTree = bookmarks.treesForEdges().value.successValue!.buffer
        XCTAssertFalse(populatedBufferTree.isEmpty)
        XCTAssertTrue(populatedBufferTree.isFullyRootedIn(mirrorTree))
        XCTAssertFalse(populatedBufferTree.find("bookmarkEEEE")!.isUnknown)
        XCTAssertFalse(populatedBufferTree.find("bookmarkCCCC")!.isUnknown)
        XCTAssertTrue(populatedBufferTree.find("bookmarkBBBB")!.isUnknown)

        // Now let's make local changes with the API.
        bookmarks.local.insertBookmark("http://example.com/d".asURL!, title: "D (local)", favicon: nil, intoFolder: "folderAAAAAA", withTitle: "A").succeeded()

        let populatedLocalTree = bookmarks.treesForEdges().value.successValue!.local
        let newMirrorTree = bookmarks.treeForMirror().value.successValue!
        XCTAssertEqual(1, newMirrorTree.subtrees.count)

        XCTAssertFalse(populatedLocalTree.isEmpty)
        XCTAssertTrue(populatedLocalTree.isFullyRootedIn(mirrorTree))
        XCTAssertTrue(populatedLocalTree.isFullyRootedIn(newMirrorTree))  // It changed.
        XCTAssertNil(populatedLocalTree.find("bookmarkEEEE"))
        XCTAssertTrue(populatedLocalTree.find("bookmarkCCCC")!.isUnknown)
        XCTAssertTrue(populatedLocalTree.find("bookmarkBBBB")!.isUnknown)
        XCTAssertFalse(populatedLocalTree.find("folderAAAAAA")!.isUnknown)

        // Now merge.
        let storageMerger = ThreeWayBookmarksStorageMerger(buffer: bookmarks, storage: bookmarks)
        let merger = storageMerger.getMerger().value.successValue!
        guard let mergedTree = merger.produceMergedTree().value.successValue else {
            XCTFail("Couldn't get merge result.")
            return
        }

        // Dump it so we can see it.
        mergedTree.dump()

        guard let menu = mergedTree.root.mergedChildren?[0] else {
            XCTFail("Expected a child of the root.")
            return
        }

        XCTAssertEqual(menu.guid, BookmarkRoots.MenuFolderGUID)
        XCTAssertEqual(menu.mergedChildren?[0].guid, "bookmarkCCCC")

        guard let toolbar = mergedTree.root.mergedChildren?[1] else {
            XCTFail("Expected a second child of the root.")
            return
        }

        XCTAssertEqual(toolbar.guid, BookmarkRoots.ToolbarFolderGUID)
        let toolbarChildren = toolbar.mergedChildren!
        XCTAssertEqual(toolbarChildren.count, 1)   // A.
        let aaa = toolbarChildren[0]
        XCTAssertEqual(aaa.guid, "folderAAAAAA")
        let aaaChildren = aaa.mergedChildren!

        XCTAssertEqual(aaaChildren.count, 3)   // B, E, new local.
        XCTAssertFalse(aaaChildren.contains { $0.guid == "bookmarkCCCC" })
    }

    func testApplyingTwoEmptyFoldersDoesntSmush() {
        guard let bookmarks = self.getSyncableBookmarks("C") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Insert two identical folders. We mark them with hasDupe because that's the Syncy
        // thing to do.
        let now = NSDate.now()
        let records = [
            BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: now, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Mobile Bookmarks", description: "", children: ["emptyempty01", "emptyempty02"]),
            BookmarkMirrorItem.folder("emptyempty01", modified: now, hasDupe: true, parentID: BookmarkRoots.MobileFolderGUID, parentName: "Mobile Bookmarks", title: "Empty", description: "", children: []),
            BookmarkMirrorItem.folder("emptyempty02", modified: now, hasDupe: true, parentID: BookmarkRoots.MobileFolderGUID, parentName: "Mobile Bookmarks", title: "Empty", description: "", children: []),
        ]

        bookmarks.buffer.applyRecords(records).succeeded()

        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBuffer)", int: 3)
        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBufferStructure)", int: 2)

        let storageMerger = ThreeWayBookmarksStorageMerger(buffer: bookmarks, storage: bookmarks)
        let merger = storageMerger.getMerger().value.successValue!
        guard let mergedTree = merger.produceMergedTree().value.successValue else {
            XCTFail("Couldn't get merge result.")
            return
        }

        // Dump it so we can see it.
        mergedTree.dump()

        // Now let's look at the tree.
        XCTAssertTrue(mergedTree.deleteFromMirror.isEmpty)
        XCTAssertEqual(BookmarkRoots.RootGUID, mergedTree.root.guid)
        XCTAssertEqual(BookmarkRoots.RootGUID, mergedTree.root.mirror?.recordGUID)
        XCTAssertNil(mergedTree.root.remote)

        XCTAssertTrue(MergeState<BookmarkMirrorItem>.Unchanged == mergedTree.root.valueState)
        XCTAssertTrue(MergeState<BookmarkTreeNode>.Unchanged == mergedTree.root.structureState)
        XCTAssertEqual(4, mergedTree.root.mergedChildren?.count)

        guard let mergedMobile = mergedTree.root.mergedChildren?[BookmarkRoots.RootChildren.indexOf(BookmarkRoots.MobileFolderGUID) ?? -1] else {
            XCTFail("Didn't get a merged mobile folder.")
            return
        }

        XCTAssertEqual(BookmarkRoots.MobileFolderGUID, mergedMobile.guid)
        XCTAssertTrue(MergeState<BookmarkMirrorItem>.Remote == mergedMobile.valueState)

        // This ends up as Remote because we didn't change any of its structure
        // when compared to the incoming record.
        guard case MergeState<BookmarkTreeNode>.Remote = mergedMobile.structureState else {
            XCTFail("Didn't get expected Remote state.")
            return
        }

        XCTAssertEqual(["emptyempty01", "emptyempty02"], mergedMobile.remote!.children!.map { $0.recordGUID })
        XCTAssertEqual(["emptyempty01", "emptyempty02"], mergedMobile.asMergedTreeNode().children!.map { $0.recordGUID })
        XCTAssertEqual(["emptyempty01", "emptyempty02"], mergedMobile.mergedChildren!.map { $0.guid })
        let empty01 = mergedMobile.mergedChildren![0]
        let empty02 = mergedMobile.mergedChildren![1]
        XCTAssertNil(empty01.local)
        XCTAssertNil(empty02.local)
        XCTAssertNil(empty01.mirror)
        XCTAssertNil(empty02.mirror)
        XCTAssertNotNil(empty01.remote)
        XCTAssertNotNil(empty02.remote)
        XCTAssertEqual("emptyempty01", empty01.remote!.recordGUID)
        XCTAssertEqual("emptyempty02", empty02.remote!.recordGUID)
        XCTAssertTrue(MergeState<BookmarkTreeNode>.Remote == empty01.structureState)
        XCTAssertTrue(MergeState<BookmarkTreeNode>.Remote == empty02.structureState)
        XCTAssertTrue(MergeState<BookmarkMirrorItem>.Remote == empty01.valueState)
        XCTAssertTrue(MergeState<BookmarkMirrorItem>.Remote == empty02.valueState)
        XCTAssertTrue(empty01.mergedChildren?.isEmpty ?? false)
        XCTAssertTrue(empty02.mergedChildren?.isEmpty ?? false)

        guard let result = merger.produceMergeResultFromMergedTree(mergedTree).value.successValue else {
            XCTFail("Couldn't get merge result.")
            return
        }

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        applier.applyResult(result).succeeded()

        guard let mirror = bookmarks.treeForMirror().value.successValue else {
            XCTFail("Couldn't get mirror!")
            return
        }

        // After merge, the buffer and local are empty.
        let edgesAfter = bookmarks.treesForEdges().value.successValue!
        XCTAssertTrue(edgesAfter.local.isEmpty)
        XCTAssertTrue(edgesAfter.buffer.isEmpty)

        // When merged in, we do not smush these two records together!
        XCTAssertFalse(mirror.isEmpty)
        XCTAssertTrue(mirror.subtrees[0].recordGUID == BookmarkRoots.RootGUID)
        XCTAssertNotNil(mirror.find("emptyempty01"))
        XCTAssertNotNil(mirror.find("emptyempty02"))
        XCTAssertTrue(mirror.deleted.isEmpty)
        guard let mobile = mirror.find(BookmarkRoots.MobileFolderGUID) else {
            XCTFail("No mobile folder in mirror.")
            return
        }

        if case let .Folder(_, children) = mobile {
            XCTAssertEqual(children.map { $0.recordGUID }, ["emptyempty01", "emptyempty02"])
        } else {
            XCTFail("Mobile isn't a folder.")
        }


        // If we try to merge again, we'll get a merge error because both sides are empty.
        let getSecondMerger = storageMerger.getMerger().value
        XCTAssertTrue(getSecondMerger.isFailure)
    }

    /**
     * Input:
     *
     *           [M]                []             [M]
     *     _______|_______                     _____|_____
     *    /       |       \                   /           \
     *  [e01]   [e02]    [e03]              [e02]        [eL0]
     *
     * Expected output:
     *
     * Take remote, delete emptyemptyL0, upload the roots that
     * weren't remotely present.
     */
    func testApplyingTwoEmptyFoldersMatchesOnlyOne() {
        guard let bookmarks = self.getSyncableBookmarks("D") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        // Insert three identical folders. We mark them with hasDupe because that's the Syncy
        // thing to do.
        let now = NSDate.now()
        let records = [
            BookmarkMirrorItem.folder(BookmarkRoots.MobileFolderGUID, modified: now, hasDupe: false, parentID: BookmarkRoots.RootGUID, parentName: "", title: "Mobile Bookmarks", description: "", children: ["emptyempty01", "emptyempty02", "emptyempty03"]),
            BookmarkMirrorItem.folder("emptyempty01", modified: now, hasDupe: true, parentID: BookmarkRoots.MobileFolderGUID, parentName: "Mobile Bookmarks", title: "Empty", description: "", children: []),
            BookmarkMirrorItem.folder("emptyempty02", modified: now, hasDupe: true, parentID: BookmarkRoots.MobileFolderGUID, parentName: "Mobile Bookmarks", title: "Empty", description: "", children: []),
            BookmarkMirrorItem.folder("emptyempty03", modified: now, hasDupe: true, parentID: BookmarkRoots.MobileFolderGUID, parentName: "Mobile Bookmarks", title: "Empty", description: "", children: []),
        ]

        bookmarks.buffer.validate().succeeded()                // It's valid! Empty.
        bookmarks.buffer.applyRecords(records).succeeded()
        bookmarks.buffer.validate().succeeded()                // It's valid! Rooted in mobile_______.

        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBuffer)", int: 4)
        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBufferStructure)", int: 3)

        // Add one matching empty folder locally.
        // Add one by GUID, too. This is the most complex possible case.
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocal) (guid, type, title, parentid, parentName, sync_status, local_modified) VALUES ('emptyempty02', \(BookmarkNodeType.Folder.rawValue), 'Empty', '\(BookmarkRoots.MobileFolderGUID)', 'Mobile Bookmarks', \(SyncStatus.Changed.rawValue), \(NSDate.now()))").succeeded()
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocal) (guid, type, title, parentid, parentName, sync_status, local_modified) VALUES ('emptyemptyL0', \(BookmarkNodeType.Folder.rawValue), 'Empty', '\(BookmarkRoots.MobileFolderGUID)', 'Mobile Bookmarks', \(SyncStatus.New.rawValue), \(NSDate.now()))").succeeded()
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES ('\(BookmarkRoots.MobileFolderGUID)', 'emptyempty02', 0)").succeeded()
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES ('\(BookmarkRoots.MobileFolderGUID)', 'emptyemptyL0', 1)").succeeded()


        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        applier.go().succeeded()

        guard let mirror = bookmarks.treeForMirror().value.successValue else {
            XCTFail("Couldn't get mirror!")
            return
        }

        // After merge, the buffer and local are empty.
        let edgesAfter = bookmarks.treesForEdges().value.successValue!

        XCTAssertTrue(edgesAfter.local.isEmpty)
        XCTAssertTrue(edgesAfter.buffer.isEmpty)

        // All of the incoming records exist.
        XCTAssertFalse(mirror.isEmpty)
        XCTAssertEqual(mirror.subtrees[0].recordGUID, BookmarkRoots.RootGUID)
        XCTAssertNotNil(mirror.find("emptyempty01"))
        XCTAssertNotNil(mirror.find("emptyempty02"))
        XCTAssertNotNil(mirror.find("emptyempty03"))

        // The other roots are now in the mirror.
        XCTAssertTrue(BookmarkRoots.Real.every({ mirror.find($0) != nil }))

        // And are queued for upload.
        XCTAssertTrue(uploader.added.contains("toolbar"))
        XCTAssertTrue(uploader.added.contains("menu"))
        XCTAssertTrue(uploader.added.contains("unfiled"))
        XCTAssertFalse(uploader.added.contains("mobile"))  // Structure and value didn't change.

        // The local record that was smushed is not present…
        XCTAssertNil(mirror.find("emptyemptyL0"))

        // … and because it was marked New, we don't bother trying to delete it.
        XCTAssertFalse(uploader.deletions.contains("emptyemptyL0"))

        guard let mobile = mirror.find(BookmarkRoots.MobileFolderGUID) else {
            XCTFail("No mobile folder in mirror.")
            return
        }

        if case let .Folder(_, children) = mobile {
            // This order isn't strictly specified, but try to preserve the remote order if we can.
            XCTAssertEqual(children.map { $0.recordGUID }, ["emptyempty01", "emptyempty02", "emptyempty03"])
        } else {
            XCTFail("Mobile isn't a folder.")
        }
    }

    // TODO: this test should be extended to also exercise the case of a conflict.
    func testLocalRecordsKeepTheirFavicon() {
        guard let bookmarks = self.getSyncableBookmarks("E") else {
            XCTFail("Couldn't get bookmarks.")
            return
        }

        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBuffer)", int: 0)
        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksBufferStructure)", int: 0)
        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksLocal)", int: 5)
        bookmarks.buffer.db.assertQueryReturns("SELECT COUNT(*) FROM \(TableBookmarksLocalStructure)", int: 4)

        bookmarks.local.db.run("INSERT INTO \(TableFavicons) (id, url, width, height, type, date) VALUES (11, 'http://example.org/favicon.ico', 16, 16, 0, \(NSDate.now()))").succeeded()
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocal) (guid, type, title, parentid, parentName, sync_status, bmkUri, faviconID) VALUES ('somebookmark', \(BookmarkNodeType.Bookmark.rawValue), 'Some Bookmark', '\(BookmarkRoots.MobileFolderGUID)', 'Mobile Bookmarks', \(SyncStatus.New.rawValue), 'http://example.org/', 11)").succeeded()
        bookmarks.local.db.run("INSERT INTO \(TableBookmarksLocalStructure) (parent, child, idx) VALUES ('\(BookmarkRoots.MobileFolderGUID)', 'somebookmark', 0)").succeeded()

        let uploader = MockUploader()
        let storer = uploader.getStorer()
        let applier = MergeApplier(buffer: bookmarks, storage: bookmarks, client: storer, greenLight: { true })
        applier.go().succeeded()

        // After merge, the buffer and local are empty.
        let edgesAfter = bookmarks.treesForEdges().value.successValue!
        XCTAssertTrue(edgesAfter.local.isEmpty)
        XCTAssertTrue(edgesAfter.buffer.isEmpty)

        // New record was uploaded.
        XCTAssertTrue(uploader.added.contains("somebookmark"))

        // So were all the roots, with the Sync-native names.
        XCTAssertTrue(uploader.added.contains("toolbar"))
        XCTAssertTrue(uploader.added.contains("menu"))
        XCTAssertTrue(uploader.added.contains("unfiled"))
        XCTAssertTrue(uploader.added.contains("mobile"))

        // … but not the Places root.
        XCTAssertFalse(uploader.added.contains("places"))
        XCTAssertFalse(uploader.added.contains(BookmarkRoots.RootGUID))

        // Their parent IDs are translated.
        XCTAssertEqual(uploader.records["mobile"]?.payload["parentid"].asString, "places")
        XCTAssertEqual(uploader.records["somebookmark"]?.payload["parentid"].asString, "mobile")

        XCTAssertTrue(uploader.deletions.isEmpty)

        // The record looks sane.
        let bm = uploader.records["somebookmark"]!
        XCTAssertEqual("bookmark", bm.payload["type"].asString)
        XCTAssertEqual("Some Bookmark", bm.payload["title"].asString)

        // New record still has its icon ID in the local DB.
        bookmarks.local.db.assertQueryReturns("SELECT faviconID FROM \(TableBookmarksMirror) WHERE bmkUri = 'http://example.org/'", int: 11)
    }
}

class TestMergedTree: FailFastTestCase {
    func testInitialState() {
        let children = BookmarkRoots.RootChildren.map { BookmarkTreeNode.Unknown(guid: $0) }
        let root = BookmarkTreeNode.Folder(guid: BookmarkRoots.RootGUID, children: children)
        let tree = MergedTree(mirrorRoot: root)
        XCTAssertTrue(tree.root.hasDecidedChildren)

        if case let .Folder(guid, unmergedChildren) = tree.root.asUnmergedTreeNode() {
            XCTAssertEqual(guid, BookmarkRoots.RootGUID)
            XCTAssertEqual(unmergedChildren, children)
        } else {
            XCTFail("Root should start as Folder.")
        }

        // We haven't processed the children.
        XCTAssertNil(tree.root.mergedChildren)
        XCTAssertTrue(tree.root.asMergedTreeNode().isUnknown)

        // Simulate a merge.
        let mergedRoots = children.map { MergedTreeNode(guid: $0.recordGUID, mirror: $0, structureState: MergeState.Unchanged) }
        tree.root.mergedChildren = mergedRoots

        // Now we have processed children.
        XCTAssertNotNil(tree.root.mergedChildren)
        XCTAssertFalse(tree.root.asMergedTreeNode().isUnknown)
    }
}

private extension MergedSQLiteBookmarks {
    func populateMirrorViaBuffer(items: [BookmarkMirrorItem], atDate mirrorDate: Timestamp) {
        self.applyRecords(items).succeeded()

        // … and add the root relationships that will be missing (we don't do those for the buffer,
        // so we need to manually add them and move them across).
        self.buffer.db.run([
            "INSERT INTO \(TableBookmarksBufferStructure) (parent, child, idx) VALUES",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.MenuFolderGUID)', 0),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.ToolbarFolderGUID)', 1),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.UnfiledFolderGUID)', 2),",
            "('\(BookmarkRoots.RootGUID)', '\(BookmarkRoots.MobileFolderGUID)', 3)",
        ].joinWithSeparator(" ")).succeeded()

        // Move it all to the mirror.
        self.local.db.moveBufferToMirrorForTesting()
    }

    func wipeLocal() {
        self.local.db.run(["DELETE FROM \(TableBookmarksLocalStructure)", "DELETE FROM \(TableBookmarksLocal)"]).succeeded()
    }
}