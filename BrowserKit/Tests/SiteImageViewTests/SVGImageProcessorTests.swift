// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView
import SwiftDraw
import Kingfisher

class SVGImageProcessorTests: XCTestCase {
    let svgFaviconURL = URL(string: "https://news.ycombinator.com/y18.svg")!
    let icoFaviconURL = URL(string: "https://www.mozilla.org/favicon.ico")!

    func testDownloadingSVGImage_withKingfisherProcessor() async {
        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: svgFaviconURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Should not have an error: \(error) \(error.errorDescription ?? "")")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testDownloadingICOImage_withKingfisherProcessor() async {
        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: icoFaviconURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success:
                exp.fulfill()
            case .failure(let error):
                XCTFail("Should not have an error: \(error) \(error.errorDescription ?? "")")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testParsingAndRasterizingSVG_fromWebData() async {
        let rasterSize = CGSize(width: 240, height: 240)

        guard let svgData = try? Data(contentsOf: svgFaviconURL) else {
            XCTFail("Failed to download SVG image")
            return
        }

        guard let svgParsed = SVG(data: svgData) else {
            XCTFail("Failed to parse SVG data")
            return
        }

        // Test
        let imageFromData = svgParsed.rasterize(with: rasterSize)
        XCTAssertEqual(imageFromData.size, rasterSize)
    }
}
