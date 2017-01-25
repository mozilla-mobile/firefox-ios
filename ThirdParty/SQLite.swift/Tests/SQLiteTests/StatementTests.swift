import XCTest
import SQLite

class StatementTests : SQLiteTestCase {
    override func setUp() {
        super.setUp()
        CreateUsersTable()
    }

    func test_cursor_to_blob() {
        try! InsertUsers("alice")
        let statement = try! db.prepare("SELECT email FROM users")
        XCTAssert(try! statement.step())
        let blob = statement.row[0] as Blob
        XCTAssertEqual("alice@example.com", String(bytes: blob.bytes, encoding: .utf8)!)
    }

    func test_zero_sized_blob_returns_null() {
        let blobs = Table("blobs")
        let blobColumn = Expression<Blob>("blob_column")
        try! db.run(blobs.create { $0.column(blobColumn) })
        try! db.run(blobs.insert(blobColumn <- Blob(bytes: [])))
        let blobValue = try! db.scalar(blobs.select(blobColumn).limit(1, offset: 0))
        XCTAssertEqual([], blobValue.bytes)
    }
}
