import Foundation
import XCTest

class TestBookmarks : XCTestCase {
    var db: SwiftData!

    private func addBookmark(bookmarks: BookmarkTable<BookmarkNode>, url: String, title: String, s: Bool = true) -> BookmarkNode {
        var inserted = -1;
        let bookmark = BookmarkItem(guid: NSUUID().UUIDString, title: title, url: url)
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            inserted = bookmarks.insert(connection, item: bookmark, err: &err)
            return err
        }

        if s {
            XCTAssert(inserted >= 0, "Inserted succeeded")
        } else {
            XCTAssert(inserted == -1, "Inserted failed")
        }

        return bookmark
    }

    private func updateBookmark(bookmarks: BookmarkTable<BookmarkNode>, bookmark: BookmarkNode, url: String, title: String, s: Bool = true) -> BookmarkNode {
        var updated = -1;
        let newBookmark = BookmarkItem(guid: bookmark.guid, title: title, url: url)
        db.withConnection(.ReadWrite) { connection -> NSError? in
            let site = Site(url: url, title: title)
            var err: NSError? = nil
            updated = bookmarks.update(connection, item: newBookmark, err: &err)
            return err
        }

        if s {
            XCTAssert(updated >= 0, "Update succeeded")
        } else {
            XCTAssert(updated == -1, "Update failed")
        }

        return newBookmark
    }

    private func find(bookmark: BookmarkNode, expected: [BookmarkNode]) -> Int? {
        for (index, item) in enumerate(expected) {
            if item.guid == bookmark.guid && item.title == bookmark.title {
                return index
            }
        }
        return nil
    }

    private func checkBookmarks(bookmarks: BookmarkTable<BookmarkNode>,
            options: QueryOptions?,
            expected: [BookmarkNode],
            s: Bool = true) {
        db.withConnection(.ReadOnly) { connection -> NSError? in
            var cursor = bookmarks.query(connection, options: options)
            XCTAssertEqual(cursor.status, CursorStatus.Success, "returned success \(cursor.statusMessage)")
            XCTAssertEqual(cursor.count, expected.count, "cursor has right num of entries")

            for index in 0..<cursor.count {
                if let s = cursor[index] as? BookmarkItem {
                    XCTAssertNotNil(s, "cursor has a site for entry")
                    XCTAssertNotNil(self.find(s, expected: expected), "Found expected bookmark in list")
                } else {
                    XCTFail("Could not cast bookmark from cursor")
                }
            }
            return nil
        }
    }

    private func clear(bookmarks: BookmarkTable<BookmarkNode>, bookmark: BookmarkNode? = nil, s: Bool = true) {
        var deleted = -1;
        db.withConnection(.ReadWrite) { connection -> NSError? in
            var err: NSError? = nil
            deleted = bookmarks.delete(connection, item: bookmark, err: &err)
            return nil
        }

        if s {
            XCTAssert(deleted >= 0, "Delete worked")
        } else {
            XCTAssert(deleted == -1, "Delete failed")
        }
    }

    // This is a very basic test. Adds an entry. Retrieves it, and then clears the database
    func testBookmarksTable() {
        let files = MockFiles()
        self.db = SwiftData(filename: files.get("test.db")!)
        let bookmarks = BookmarkTable<BookmarkNode>()

        self.db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            bookmarks.create(db, version: 1)
            return nil
        })

        var bookmark1 = self.addBookmark(bookmarks, url: "url1", title: "title1")
        let bookmark2 = self.addBookmark(bookmarks, url: "url1", title: "title1")
        bookmark1 = self.updateBookmark(bookmarks, bookmark: bookmark1, url: "url1", title: "title1 alt")
        let bookmark3 = self.addBookmark(bookmarks, url: "url2", title: "title2")
        let bookmark4 = self.addBookmark(bookmarks, url: "url2", title: "title2")

        self.checkBookmarks(bookmarks, options: nil, expected: [bookmark1, bookmark2, bookmark3, bookmark4])

        let options = QueryOptions()
        options.filter = bookmark3.guid
        self.checkBookmarks(bookmarks, options: options, expected: [bookmark3])

        var site = Site(url: "url1", title: "title1 alt")
        self.clear(bookmarks, bookmark: bookmark1, s: true)
        self.checkBookmarks(bookmarks, options: nil, expected: [bookmark2, bookmark3, bookmark4])
        self.clear(bookmarks)
        self.checkBookmarks(bookmarks, options: nil, expected: [BookmarkNode]())
        
        files.remove("test.db")
    }
}