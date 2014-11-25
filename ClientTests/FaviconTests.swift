// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import XCTest

// TODO: Move this to an AccountTest 
class FaviconTests: XCTestCase {
    func testEquality() {
        var siteUrl = NSURL(string: "http://www.example.com");
        var siteUrl2 = NSURL(string: "http://www.example2.com");
        var sourceUrl = FaviconConsts.DefaultFaviconUrl
        var sourceUrl2 = NSURL(string: "http://www.example.com/favicon.ico");

        var icon = Favicon(url: sourceUrl)
        var icon2 = Favicon(url: sourceUrl2!)

        XCTAssertEqual(icon, icon, "Compare to yourself")
        XCTAssertEqual(icon, Favicon(url: sourceUrl), "Compare to a different (but same) icon")
        XCTAssertNotEqual(icon, icon2, "Compare to a different icon")
    }

    func testLoadingFavicon() {
        var fav : Favicons = BasicFavicons();
        var url = NSURL(string: "http://www.example.com");

        var expectation = expectationWithDescription("asynchronous request")
        fav.getForUrl(url!, options: nil, callback: { (data: [Favicon]) -> Void in
            XCTAssertEqual(data[0].url, FaviconConsts.DefaultFaviconUrl, "Source url is correct");
            expectation.fulfill()
        });
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }


    func testLoadingFavicons() {
        var expectation = expectationWithDescription("asynchronous request")
        var url = NSURL(string: "http://www.example.com");
        var urls = [url!, url!, url!];
        var fav : Favicons = BasicFavicons();
        fav.getForUrls(urls, options: nil, callback: { (data: ArrayCursor<[Favicon]>) -> Void in
            XCTAssertTrue(data.count == urls.count, "At least one favicon was returned for each url requested")

            var favicons : [Favicon] = data[0]!
            XCTAssertEqual(favicons[0].url, FaviconConsts.DefaultFaviconUrl, "Favicon url is correct")

            // Favicons are now loaded asynchronously
            // XCTAssertNotNil(favicon.img!, "Favicon image is not null");

            expectation.fulfill()
        });
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }

    func testLoadingRealFavicon() {
        var expectation = expectationWithDescription("asynchronous request")
        var url = NSURL(string: "http://m.wsj.com")
        var fav : Favicons = BasicFavicons()

        // This will trigger a download of the page, and a parse to find favicons inside it
        fav.getForUrl(url!, options: nil, callback: { data -> Void in
            var WSJUrl = NSURL(string: "/img/wsj-com.ico", relativeToURL: url)
            XCTAssertEqual(data[0].url, WSJUrl!, "Favicon url is correct")
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(10.0, handler:nil)
    }

    func testLoadingGoogleFavicon() {
        var expectation = expectationWithDescription("asynchronous request")
        var url = NSURL(string: "http://www.google.com")
        var fav : Favicons = BasicFavicons()

        // This will trigger a download of the page, and a parse to find favicons inside it
        fav.getForUrl(url!, options: nil, callback: { data -> Void in
            var iconURL = NSURL(string: "favicon.ico", relativeToURL: url)
            XCTAssertEqual(data[0].url.absoluteString!, iconURL!.absoluteString!, "Favicon url is correct")
            expectation.fulfill()
        })
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }

    private class MyUIImage: UIImageView {
        var cb: (image: UIImage?) -> Void

        override init(frame: CGRect) {
            // ?
            self.cb = { image in
            }
            super.init(frame: frame)
        }

        init(cb: (image: UIImage?) -> Void) {
            self.cb = cb
            super.init()
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc override var image: UIImage? {
            get { return super.image }
            set {
                super.image = newValue
                cb(image: newValue)
            }
        }
    }

    private class MyCell : UITableViewCell {
        let _imageView: MyUIImage

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            _imageView = MyUIImage({ image in })
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }

        override init(frame: CGRect) {
            _imageView = MyUIImage({ image in })
            super.init(frame: frame)
        }

        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc override var imageView: UIImageView { return _imageView }
    }

    func testLoadIntoCell() {
        var expectation = expectationWithDescription("asynchronous request")
        var fav : Favicons = BasicFavicons()
        var c = MyCell(style: UITableViewCellStyle.Default, reuseIdentifier: "Test")
        var count = 0;
        c._imageView.cb = { img in
            XCTAssertNotNil(img)
            count++
            // This fires twice, once for the placeholder and once for the real image
            if (count == 2) {
                expectation.fulfill()
            }
        }
        fav.loadIntoCell("http://www.google.com", view: c)
        waitForExpectationsWithTimeout(10.0, handler:nil)
    }
}
