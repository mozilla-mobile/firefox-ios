import XCTest
import SQLite

class BlobTests : XCTestCase {

    func test_toHex() {
        let blob = Blob(bytes: [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 150, 250, 255])

        XCTAssertEqual(blob.toHex(), "000a141e28323c46505a6496faff")
    }

    func test_init_array() {
        let blob = Blob(bytes: [42, 42, 42])
        XCTAssertEqual(blob.bytes, [42, 42, 42])
    }

    func test_init_unsafeRawPointer() {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
        pointer.initialize(to: 42, count: 3)
        let blob = Blob(bytes: pointer, length: 3)
        XCTAssertEqual(blob.bytes, [42, 42, 42])
    }
}
