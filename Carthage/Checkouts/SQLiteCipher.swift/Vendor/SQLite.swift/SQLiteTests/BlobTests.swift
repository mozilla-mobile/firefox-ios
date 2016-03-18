import XCTest
@testable import SQLite

class BlobTests : XCTestCase {

    func test_toHex() {
        let blob = Blob(bytes: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 250, 255])

        XCTAssertEqual(blob.toHex(), "000a141e28323c46505a6496faff")
    }

}
