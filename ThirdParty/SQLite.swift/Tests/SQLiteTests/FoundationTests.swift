import XCTest
import SQLite

class FoundationTests : XCTestCase {
    func testDataFromBlob() {
        let data = Data(bytes: [1, 2, 3])
        let blob = data.datatypeValue
        XCTAssertEqual([1, 2, 3], blob.bytes)
    }

    func testBlobToData() {
        let blob = Blob(bytes: [1, 2, 3])
        let data = Data.fromDatatypeValue(blob)
        XCTAssertEqual(Data(bytes: [1, 2, 3]), data)
    }
}
