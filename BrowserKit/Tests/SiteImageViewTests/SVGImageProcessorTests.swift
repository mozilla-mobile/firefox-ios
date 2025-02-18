// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView
import SwiftDraw
import Kingfisher
import GCDWebServers

class SVGImageProcessorTests: XCTestCase {
    func testDownloadingSVGImage_withKingfisherProcessor_forStandardSVGCase() async {
        let assetType: AssetType = .svgCase1
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

    /// FXIOS-11361: Tests a special SVG which previously caused crashes in older versions of SwiftDraw.
    func testDownloadingSVGImage_withKingfisherProcessor_forSpecialSVGCase() async {
        let assetType: AssetType = .svgCase2
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

    func testDownloadingGarbageData_withKingfisherProcessor() async {
        guard let garbageData = try? dataFor(type: .badType) else {
            XCTFail("Could not load test asset")
            return
        }

        guard let mockedURL = try? await startMockImageServer(imageData: garbageData, forAssetType: .badType) else {
            XCTFail("Check bundle setup for mock server response data")
            return
        }

        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: mockedURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success:
                XCTFail("We shouldn't get an image for bad data")
                exp.fulfill()
            case .failure:
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func testDownloadingEmptyImage_withKingfisherProcessor() async {
        let emptyData = Data()

        guard let mockedURL = try? await startMockImageServer(imageData: emptyData, forAssetType: .ico) else {
            XCTFail("Check bundle setup for mock server response data")
            return
        }

        let exp = expectation(description: "Image download and parse")

        let siteDownloader = DefaultSiteImageDownloader()
        siteDownloader.downloadImage(with: mockedURL, options: [.processor(SVGImageProcessor())]) { result in
            switch result {
            case .success:
                XCTFail("We shouldn't get an image for empty data")
                exp.fulfill()
            case .failure:
                exp.fulfill()
            }
        }

        await fulfillment(of: [exp], timeout: 2.0)
    }
}

extension SVGImageProcessorTests {
    enum MockImageServerError: Error {
        case noAssetData
        case badData
    }

    enum AssetType {
        case ico
        case svgCase1
        case svgCase2
        case badType

        var contentType: String {
            switch self {
            case .ico:
                return "image/x-icon"
            case .svgCase1, .svgCase2:
                return "image/svg+xml"
            case .badType:
                return "garbage asset type $23%12@!!!//asd"
            }
        }
    }

    func dataFor(type: AssetType) throws -> Data {
        let fileURL: URL?

        switch type {
        case .ico:
            fileURL = Bundle.module.url(forResource: "mozilla", withExtension: "ico")
        case .svgCase1:
            fileURL = Bundle.module.url(forResource: "hackernews", withExtension: "svg")
        case .svgCase2:
            fileURL = Bundle.module.url(forResource: "inf-nan", withExtension: "svg")
        case .badType:
            guard let badData = "some non-image data".data(using: .utf8) else {
                throw MockImageServerError.badData
            }
            return badData
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
