/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

class TestReadingListTable: XCTestCase {
    var db: SwiftData!
    var readingListTable: ReadingListTable<ReadingListItem>!

    override func setUp() {
        let files = MockFiles()
        files.remove("TestReadingListTable.db")
        db = SwiftData(filename: files.getAndEnsureDirectory()!.stringByAppendingPathComponent("TestReadingListTable.db"))

        readingListTable = ReadingListTable<ReadingListItem>()
        db.withConnection(SwiftData.Flags.ReadWriteCreate, cb: { (db) -> NSError? in
            XCTAssertTrue(self.readingListTable.create(db, version: 1))
            return nil
        })
    }

    func testInsertQueryDelete() {
        // Insert some entries, make sure they got ids

        let items = [
            ReadingListItem(url: "http://one.com", title: "One"),
            ReadingListItem(url: "http://two.com", title: "Two"),
            ReadingListItem(url: "http://thr.com", title: "Thr")
        ]

        var insertedItems = [ReadingListItem]()

        for item in items {
            let r = addItem(item)
            XCTAssertNil(r.error)
            XCTAssertNotNil(r.item.id)
            insertedItems.append(r.item)
        }

        // Retrieve them, make sure they are equal

        db.withConnection(.ReadOnly, cb: { (connection) -> NSError? in
            var cursor = self.readingListTable.query(connection, options: nil)
            XCTAssertEqual(cursor.status, CursorStatus.Success)
            XCTAssertEqual(cursor.count, 3)

            for index in 0..<cursor.count {
                if let item = cursor[index] as? ReadingListItem {
                    XCTAssertEqual(item.id!, insertedItems[countElements(insertedItems)-index-1].id!)
                    XCTAssertEqual(item.clientLastModified, insertedItems[countElements(insertedItems)-index-1].clientLastModified)
                } else {
                    XCTFail("Did not get a ReadingListItem back (nil or wrong type)")
                }
            }

            return nil
        })

        // Delete them, make sure they are gone

        db.withConnection(.ReadWrite, cb: { (connection) -> NSError? in
            for item in insertedItems {
                var error: NSError?
                self.readingListTable.delete(connection, item: item, err: &error)
                XCTAssertNil(error)
            }
            return nil
        })

        db.withConnection(.ReadOnly, cb: { (connection) -> NSError? in
            var cursor = self.readingListTable.query(connection, options: nil)
            XCTAssertEqual(cursor.status, CursorStatus.Success)
            XCTAssertEqual(cursor.count, 0)
            return nil
        })
    }

    func testUpdate() {
        // Insert a new item

        let (item, error) = addItem(ReadingListItem(url: "http://one.com", title: "One"))
        XCTAssertNotNil(item)
        XCTAssertNil(error)

        XCTAssert(item.clientLastModified != 0)
        XCTAssert(item.isUnread == true)

        // Mark it as read and update it

        item.isUnread = false
        db.withConnection(.ReadWrite, cb: { (connection) -> NSError? in
            var error: NSError?
            self.readingListTable.update(connection, item: item, err: &error)
            XCTAssertNil(error)
            return nil
        })

        // Fetch the item, see if it has updated

        let (updatedItem, success) = getItem(item.id!)
        XCTAssertTrue(success)
        XCTAssertNotNil(updatedItem)

        XCTAssertEqual(item.id!, updatedItem!.id!)

        XCTAssertTrue(updatedItem!.clientLastModified != 0)
        //XCTAssertTrue(item.clientLastModified < updatedItem!.clientLastModified) // TODO: See bug 1132504

        XCTAssert(updatedItem!.isUnread == false)
    }

    private func addItem(var item: ReadingListItem) -> (item: ReadingListItem, error: NSError?) {
        var error: NSError?
        db.withConnection(.ReadWrite, cb: { (connection) -> NSError? in
            item.id = self.readingListTable.insert(connection, item: item, err: &error)
            return nil
        })
        return (item, error)
    }

    private func getItem(id: Int) -> (item: ReadingListItem?, success: Bool) {
        var item: ReadingListItem?
        var success: Bool = false
        db.withConnection(.ReadOnly, cb: { (connection) -> NSError? in
            var cursor = self.readingListTable.query(connection, options: QueryOptions(filter: id, filterType: FilterType.None, sort: QuerySort.None))
            if cursor.status == .Success {
                success = true
                if cursor.count == 1 {
                    item = cursor[0] as ReadingListItem?
                }
            }
            return nil
        })
        return (item, success)
    }
}