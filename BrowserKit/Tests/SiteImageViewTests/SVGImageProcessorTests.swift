// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView
import SwiftDraw
import Kingfisher
import GCDWebServers

class SVGImageProcessorTests: XCTestCase {
    func testDownloadingSVGImage_withKingfisherProcessor() async {
        let assetType: AssetType = .svg
        let expectedRasterSize = CGSize(width: 360, height: 360)

        guard let imageData = try? dataFor(type: assetType) else {
            XCTFail("Could not load test asset")
            return
        }

        guard let mockedURL = try? await startMockImageServer(imageData: imageData, forAssetType: assetType) else {
            XCTFail("Check bundle setup for mock server response data")
            return
        }

        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: mockedURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success(let result):
                XCTAssertEqual(result.originalData, imageData)
                XCTAssertEqual(result.url, mockedURL)
                XCTAssertEqual(result.image.size, expectedRasterSize)
                exp.fulfill()
            case .failure(let error):
                XCTFail("Should not have an error: \(error) \(error.errorDescription ?? "")")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testDownloadingICOImage_withKingfisherProcessor() async {
        let assetType: AssetType = .ico

        guard let imageData = try? dataFor(type: assetType) else {
            XCTFail("Could not load test asset")
            return
        }

        guard let mockedURL = try? await startMockImageServer(imageData: imageData, forAssetType: assetType) else {
            XCTFail("Check bundle setup for mock server response data")
            return
        }

        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: mockedURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success(let result):
                XCTAssertEqual(result.originalData, imageData)
                XCTAssertEqual(result.url, mockedURL)
                exp.fulfill()
            case .failure(let error):
                XCTFail("Should not have an error: \(error) \(error.errorDescription ?? "")")
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }
}

extension SVGImageProcessorTests {
    enum MockImageServerError: Error {
        case noAssetData
    }

    enum AssetType {
        case ico
        case svg

        var contentType: String {
            switch self {
            case .ico:
                return "image/x-icon"
            case .svg:
                return "image/svg+xml"
            }
        }
    }

    func dataFor(type: AssetType) throws -> Data {
        let fileURL: URL?

        switch type {
        case .ico:
            fileURL = Bundle.module.url(forResource: "mozilla", withExtension: "ico")
        case .svg:
            fileURL = Bundle.module.url(forResource: "hackernews", withExtension: "svg")
        }

        if let fileURL {
            do {
                return try Data(contentsOf: fileURL)
            } catch {
                throw MockImageServerError.noAssetData
            }
        }

        throw MockImageServerError.noAssetData
    }

    @MainActor
    func startMockImageServer(imageData: Data, forAssetType assetType: AssetType) throws -> URL {
        let webServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET",
                             path: "/",
                             request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            return GCDWebServerDataResponse(data: imageData, contentType: assetType.contentType)
        }

        if !webServer.start(withPort: 0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        return URL(string: "http://localhost:\(webServer.port)")!
    }
}
