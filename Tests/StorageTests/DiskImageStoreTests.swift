// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
@testable import Storage
import UIKit
import XCTest

class DiskImageStoreTests: XCTestCase {
    var files: FileAccessor!
    var store: DiskImageStore!

    override func setUp() {
        super.setUp()
        files = MockFiles()
        store = DefaultDiskImageStore(files: files, namespace: "DiskImageStoreTests", quality: 1)

        clearStore()
    }

    override func tearDown() {
        super.tearDown()

        clearStore()

        files = nil
        store = nil
    }

    func testSaveImageForKey() async throws {
        let testKey = "testImageKey"
        let testImage = makeImageWithColor(UIColor.red, size: CGSize(width: 100, height: 100))

        try await store.saveImageForKey(testKey, image: testImage)

        var fetchedImage: UIImage?
        var fetchError: Error?
        do {
            fetchedImage = try await store.getImageForKey(testKey)
        } catch {
            fetchError = error
        }

        XCTAssertNil(fetchError, "Error occurred while loading image: \(fetchError!)")
        XCTAssertNotNil(fetchedImage, "Fetched image should not be nil")

        XCTAssertEqual(testImage.size.width / 2, fetchedImage!.size.width, "Fetched image width should be half the original width")
        XCTAssertEqual(testImage.size.height / 2, fetchedImage!.size.height, "Fetched image height should be half the original height")
    }

    func testGetImageForKey() async throws {
        let redImage = makeImageWithColor(UIColor.red, size: CGSize(width: 100, height: 100))
        let blueImage = makeImageWithColor(UIColor.blue, size: CGSize(width: 18, height: 18))
        let imageKeyPairs = [(key: "blueImageTestKey", image: blueImage), (key: "redImageTestKey", image: redImage)]

        for (key, image) in imageKeyPairs {
            try await store.saveImageForKey(key, image: image)

            // When
            var fetchedImage: UIImage?
            var fetchError: Error?
            do {
                fetchedImage = try await store.getImageForKey(key)
            } catch {
                fetchError = error
            }

            // Then
            XCTAssertNil(fetchError, "Error occurred while loading image: \(fetchError!)")
            XCTAssertNotNil(fetchedImage, "Fetched image should not be nil")

            XCTAssertEqual(image.size.width / 2, fetchedImage!.size.width, "Fetched image width should be half the original width")
            XCTAssertEqual(image.size.height / 2, fetchedImage!.size.height, "Fetched image height should be half the original height")
        }
    }
}

// MARK: Helper methods
private extension DiskImageStoreTests {
    func clearStore() {
        Task {
            try? await store?.clearAllScreenshotsExcluding(Set())
        }
    }

    func makeImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}
