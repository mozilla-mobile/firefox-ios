// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import XCTest

typealias ImgCallback = (image: UIImage?) -> Void

// TODO: Move this to an AccountTest
class ImageLoaderTests: XCTestCase {

    // a Fake UI Image that calls a callback when its image property is set
    private class MyUIImage: UIImageView {
        var mycb: ImgCallback? = nil

        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        init(cb: ImgCallback) {
            self.mycb = cb
            var rect = CGRect()
            super.init(frame: rect)
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc override var image: UIImage? {
            get { return super.image }
            set {
                super.image = newValue
                if (mycb != nil) {
                    mycb!(image: newValue)
                }
            }
        }
    }

    func testLoader() {
        var expectation = expectationWithDescription("asynchronous request")

        var imageView = MyUIImage(cb: { (image: UIImage?) -> Void in
            XCTAssertTrue(true, "Image was inserted")
        })

        var loader = ImageLoader({ () -> NSURL in return FaviconConsts.DefaultFaviconUrl } )
            .into(imageView)
            .then() { (img: UIImage?) -> UIImage? in
                expectation.fulfill()
                return img
        }
        waitForExpectationsWithTimeout(10.0, handler:nil)
        XCTAssertNotNil(imageView.image, "Image was set")
    }

    func testPostProcess() {
        var expectation = expectationWithDescription("asynchronous request")
        var icon2 = UIImage(named: "email")
        var icon3 = UIImage(named: "guidelines-logo")

        var imageView = MyUIImage(cb: { image in
            XCTAssertTrue(image!.isEqual(icon3), "Correct image passed to then")
        })

        var loader = ImageLoader({ () -> NSURL in return FaviconConsts.DefaultFaviconUrl } )
            .then() { (img: UIImage?) -> UIImage? in
                // Test that this is called before the image is set
                var favicon = UIImage(named: "defaultFavicon")
                XCTAssertTrue(img!.isEqual(favicon), "Correct image passed to then")
                XCTAssertNil(imageView.image, "First then is called before setting")
                return icon2
            }.then({ (img: UIImage?) -> UIImage? in
                XCTAssertTrue(img!.isEqual(icon2), "Correct image passed to then")
                XCTAssertNil(imageView.image, "Second then is called before setting")
                return icon3
            }).into(imageView)
            .then() { (img: UIImage?) -> UIImage? in
                XCTAssertNotNil(imageView.image, "Third then is called after setting")
                XCTAssertTrue(img!.isEqual(icon3), "Correct image passed to then")
                return icon2
            }.then() { (img: UIImage?) -> UIImage? in
                XCTAssertNotNil(imageView.image, "Fourth then is called after setting")
                XCTAssertTrue(img!.isEqual(icon2), "Correct image passed to then")
                expectation.fulfill()
                return icon2
        }

        waitForExpectationsWithTimeout(10.0, handler:nil)
        XCTAssertNotNil(imageView.image, "Image was set")
    }

    func testPlaceholder() {
        var expectation = expectationWithDescription("asynchronous request")
        var icon2 = UIImage(named: "email")
        var placeholderAdded = false

        var expectedIcon = icon2
        var imageView = MyUIImage(cb: { image in
            XCTAssertTrue(image!.isEqual(expectedIcon), "Correct image set")
            if (expectedIcon!.isEqual(icon2)) {
                expectedIcon = UIImage(named: "defaultFavicon")
                placeholderAdded = true
            }
        })

        var loader = ImageLoader({ () -> NSURL in return FaviconConsts.DefaultFaviconUrl } )
            .placeholder(icon2!)
            .into(imageView)
            .then() { (img: UIImage?) -> UIImage? in
                expectation.fulfill()
                return img
        }

        waitForExpectationsWithTimeout(10.0, handler:nil)
        XCTAssertTrue(placeholderAdded, "Placeholder was added")
    }

    func testViewRecycling() {
        var expectation = expectationWithDescription("asynchronous request")
        var imageView = MyUIImage(cb: { image in })

        ImageLoader({ () -> NSURL in return FaviconConsts.DefaultFaviconUrl } )
            .into(imageView)
            .then() { (img: UIImage?) -> UIImage? in
                XCTAssertFalse(true, "First load should not finish")
                return img
        }

        ImageLoader({ () -> NSURL in return NSURL(string: "resource://email")! } )
            .into(imageView)
            .then() { (img: UIImage?) -> UIImage? in
                XCTAssertFalse(false, "Second load should finish")
                expectation.fulfill()
                return img
        }

        waitForExpectationsWithTimeout(10.0, handler:nil)
    }

}
