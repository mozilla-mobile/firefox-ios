/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest
import Storage

class ThumbnailTests: ProfileTest {
    var profile: Profile!

    override func setUp() {
        let expectation = self.expectationWithDescription("Got profile")
        withTestProfile { (profile: Profile) in
            self.profile = profile
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)

        self.clearThumbnails()
    }

    func testThumbnails() {
        // Use existing assets as dummy thumbnail images.
        let backImage = UIImage(named: "back")!
        let forwardImage = UIImage(named: "forward")!
        let backPNG = UIImagePNGRepresentation(backImage)
        let forwardPNG = UIImagePNGRepresentation(forwardImage)
        let url = NSURL(string: "http://www.mozilla.org")!

        // Make sure there's no thumbnail at the start of the test.
        var thumbnail: Thumbnail! = getThumbnail(url)
        XCTAssertNil(thumbnail, "Thumbnail does not exist")

        // Test saving and reading the back thumbnail.
        setThumbnail(url, thumbnail: Thumbnail(image: backImage))
        thumbnail = getThumbnail(url)
        var thumbnailPNG = UIImagePNGRepresentation(thumbnail.image)
        XCTAssertEqual(thumbnailPNG, backPNG, "Saved thumbnail matches back image")
        XCTAssertNotEqual(thumbnailPNG, forwardPNG, "Saved thumbnail does not match forward image")

        // Test saving and reading the forward thumbnail.
        setThumbnail(url, thumbnail: Thumbnail(image: forwardImage))
        thumbnail = getThumbnail(url)
        thumbnailPNG = UIImagePNGRepresentation(thumbnail.image)
        XCTAssertEqual(thumbnailPNG, forwardPNG, "Saved thumbnail matches forward image")
        XCTAssertNotEqual(thumbnailPNG, backPNG, "Saved thumbnail does not match back image")

        // Test clearing thumbnails.
        clearThumbnails()
        thumbnail = getThumbnail(url)
        XCTAssertNil(thumbnail, "Thumbnail was cleared")
    }

    private func getThumbnail(url: NSURL) -> Thumbnail? {
        var result: Thumbnail?
        let expectation = self.expectationWithDescription(nil)
        profile.thumbnails.get(url, complete: { (thumbnail: Thumbnail?) in
            result = thumbnail
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
        return result
    }

    private func setThumbnail(url: NSURL, thumbnail: Thumbnail) {
        let expectation = self.expectationWithDescription(nil)
        profile.thumbnails.set(url, thumbnail: thumbnail, complete: { (success: Bool) in
            XCTAssertTrue(success, "Thumbnail saved")
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    private func clearThumbnails() {
        let expectation = self.expectationWithDescription(nil)
        profile.thumbnails.clear { (success: Bool) in
            XCTAssertTrue(success, "Thumbnails cleared")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
}