// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import XCTest
import Storage
import SDWebImage
import GCDWebServers
import Shared

@testable import Client

class UIImageViewExtensionsTests: XCTestCase {

    func testsetIcon() {
        let url = URL(string: "http://mozilla.com")
        let imageView = UIImageView()

        let goodIcon = FaviconFetcher.letter(forUrl: url!)
        imageView.setImageAndBackground(forIcon: nil, website: url) {}
        XCTAssertEqual(imageView.image!, goodIcon, "The correct default favicon should be applied")

        imageView.setImageAndBackground(forIcon: nil, website: URL(string: "http://mozilla.com/blahblah")) {}
        XCTAssertEqual(imageView.image!, goodIcon, "The same icon should be applied to all urls with the same domain")

        imageView.setImageAndBackground(forIcon: nil, website: URL(string: "b")) {}
        XCTAssertEqual(imageView.image, FaviconFetcher.defaultFavicon, "The default favicon should be applied when no information is given about the icon")
    }

    func testAsyncDownloadCacheWithAuthenticationOfSetIcon() {
        let originalImage = UIImage(named: "bookmark")!

        WebServer.sharedInstance.registerHandlerForMethod("GET", module: "favicon", resource: "icon") { (request) -> GCDWebServerResponse in
            return GCDWebServerDataResponse(data: originalImage.pngData()!, contentType: "image/png")
        }

        let expect = expectation(description: "UIImageView async load")
        let imageLoader = ImageLoadingHandler()
        imageLoader.credential = WebServer.sharedInstance.credentials

        let favImageView = UIImageView()

        let url = URL(string: "http://localhost:\(AppInfo.webserverPort)/favicon/icon")!
        imageLoader.downloadAndCacheImageWithAuthentication(with: url) { image, err in
            if err == nil, let downloadedImage = image {
                favImageView.image = image
                XCTAssert(downloadedImage.size.width * downloadedImage.scale == favImageView.image!.size.width * favImageView.image!.scale, "The correct favicon should be applied to the UIImageView")
                expect.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testDefaultIcons() {
        let favImageView = UIImageView()

        let gFavURL = URL(string: "https://www.facebook.com/fav") // This will be fetched from tippy top sites
        let gURL = URL(string: "http://www.facebook.com")!
        let defaultItem = FaviconFetcher.bundledIcons[gURL.baseDomain!]!
        let correctImage = UIImage(contentsOfFile: defaultItem.filePath)!

        favImageView.setImageAndBackground(forIcon: Favicon(url: gFavURL!.absoluteString), website: gURL) {}

        let expect = expectation(description: "UIImageView async load")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertEqual(favImageView.backgroundColor, defaultItem.bgcolor)
            XCTAssert(correctImage.size.width * correctImage.scale == favImageView.image!.size.width * favImageView.image!.scale, "The correct default favicon should be applied to the UIImageView")
            expect.fulfill()
        }
        waitForExpectations(timeout: 5, handler: nil)
    }
}
