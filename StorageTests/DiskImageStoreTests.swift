/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import UIKit
import XCTest

class DiskImageStoreTests: XCTestCase {
    var files: FileAccessor!
    var store: DiskImageStore!

    override func setUp() {
        files = MockFiles()
        store = DiskImageStore(files: files, namespace: "DiskImageStoreTests", quality: 1)

        store.clearExcluding(Set())
    }

    func testStore() {
        var success = false

        let redImage = makeImageWithColor(UIColor.redColor())
        let blueImage = makeImageWithColor(UIColor.blueColor())

        // Sanity checks.
        XCTAssertNotEqual(redImage, blueImage, "Images are not equal")
        XCTAssertNotEqual(toJPEGImage(redImage), toJPEGImage(blueImage), "JPEG images are not equal")

        XCTAssertNil(getImage("red"), "Red key is nil")
        success = putImage("red", image: redImage)
        XCTAssert(success, "Red image added to store")
        ensureImagesAreEqual(getImage("red")!, otherImage: toJPEGImage(redImage))
        success = putImage("red", image: redImage)
        XCTAssertFalse(success, "Red image not added again")

        XCTAssertNil(getImage("blue"), "Blue key is nil")
        success = putImage("blue", image: blueImage)
        XCTAssert(success, "Blue image added to store")
        ensureImagesAreEqual(getImage("blue")!, otherImage: toJPEGImage(blueImage))
        success = putImage("blue", image: blueImage)
        XCTAssertFalse(success, "Blue image not added again")

        store.clearExcluding(Set(["red"]))
        XCTAssertNotNil(getImage("red"), "Red image still exists")
        XCTAssertNil(getImage("blue"), "Blue image cleared")
    }

    /// Converts the image to a JPEG so it matches the image in the store.
    private func toJPEGImage(image: UIImage) -> UIImage {
        return UIImage(data: UIImageJPEGRepresentation(image, 1)!)!
    }

    private func makeImageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0, 0, 1, 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    private func getImage(key: String) -> UIImage? {
        let expectation = expectationWithDescription("Get succeeded")
        var image: UIImage?
        store.get(key).upon {
            image = $0.successValue
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        return image
    }

    private func putImage(key: String, image: UIImage) -> Bool {
        let expectation = expectationWithDescription("Put succeeded")
        var success = false
        store.put(key, image: image).upon {
            success = $0.isSuccess
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        return success
    }

    private func ensureImagesAreEqual(image: UIImage, otherImage: UIImage) {
        let imageData = UIImagePNGRepresentation(image)
        let otherImageData = UIImagePNGRepresentation(otherImage)
        XCTAssertEqual(imageData, otherImageData, "Images are equal")
    }
}