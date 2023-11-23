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

    func testSaveImageForKey() async throws {
        let testKey = "testImageKey"
        let testImage = makeImageWithColor(UIColor.red, size: CGSize(width: 100, height: 100))

        try await store.saveImageForKey(testKey, image: testImage)

        let fetchedImage = try await store.getImageForKey(testKey)

        XCTAssertEqual(testImage.size.width,
                       fetchedImage.size.width,
                       "Fetched image width should be the same as the original width")
        XCTAssertEqual(testImage.size.height,
                       fetchedImage.size.height,
                       "Fetched image height should be the same as the original height")
    }

    func testGetImageForKey() async throws {
        let redImage = makeImageWithColor(UIColor.red, size: CGSize(width: 100, height: 100))
        let blueImage = makeImageWithColor(UIColor.blue, size: CGSize(width: 18, height: 18))
        let imageKeyPairs = [(key: "blueImageTestKey", image: blueImage), (key: "redImageTestKey", image: redImage)]

        for (key, image) in imageKeyPairs {
            try await store.saveImageForKey(key, image: image)

            // When
            let fetchedImage = try await store.getImageForKey(key)

            // Then
            XCTAssertEqual(image.size.width,
                           fetchedImage.size.width,
                           "Fetched image width should be the same as the original width")
            XCTAssertEqual(image.size.height,
                           fetchedImage.size.height,
                           "Fetched image height should be the same as the original height")
        }
    }

// MARK: - Helper methods

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
