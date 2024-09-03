// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView
import SwiftDraw
import Kingfisher

class SVGImageProcessorTests: XCTestCase {
    let faviconURL = URL(string: "https://news.ycombinator.com/y18.svg")!

    func testDownloadingSVGImage_withKingfisherProcessor() async {
        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: faviconURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success(let value):
                exp.fulfill()
            case .failure(let error):
                XCTFail("Should not have an error: \(error) \(error.errorDescription ?? "")")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testSVGKit_processesSVG() async {
        let rasterSize = CGSize(width: 240, height: 240)

        guard let svgData = try? Data(contentsOf: faviconURL) else {
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
