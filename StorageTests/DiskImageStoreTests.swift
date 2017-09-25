/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
@testable import Storage
import UIKit

import XCTest

class DiskImageStoreTests: XCTestCase {
    var files: FileAccessor!
    var store: DiskImageStore!

    override func setUp() {
        files = MockFiles()
        store = DiskImageStore(files: files, namespace: "DiskImageStoreTests", quality: 1)

        _ = store.clearExcluding(Set()).value
    }

    func testStore() {
        var success = false

        // Avoid image comparison and use size of the image for equality
        let redImage = makeImageWithColor(UIColor.red, size: CGSize(width: 100, height: 100))
        let blueImage = makeImageWithColor(UIColor.blue, size: CGSize(width: 17, height: 17))

        [(key: "blue", image: blueImage), (key: "red", image: redImage)].forEach() { (key, image) in
            XCTAssertNil(getImage(key), "\(key) key is nil")
            success = putImage(key, image: image)
            XCTAssert(success, "\(key) image added to store")
            XCTAssertEqual(getImage(key)!.size.width, image.size.width, "Images are equal")

            success = putImage(key, image: image)
            XCTAssertFalse(success, "\(key) image not added again")
        }

        _ = store.clearExcluding(Set(["red"])).value
        XCTAssertNotNil(getImage("red"), "Red image still exists")
        XCTAssertNil(getImage("blue"), "Blue image cleared")
    }

    private func makeImageWithColor(_ color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    private func getImage(_ key: String) -> UIImage? {
        let expectation = self.expectation(description: "Get succeeded")
        var image: UIImage?
        store.get(key).upon {
            image = $0.successValue
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        return image
    }

    private func putImage(_ key: String, image: UIImage) -> Bool {
        let expectation = self.expectation(description: "Put succeeded")
        var success = false
        store.put(key, image: image).upon {
            success = $0.isSuccess
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        return success
    }
}
