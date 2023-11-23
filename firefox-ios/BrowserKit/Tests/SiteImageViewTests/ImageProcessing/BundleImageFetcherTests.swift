// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import SiteImageView

final class BundleImageFetcherTests: XCTestCase {
    private var bundleDataProvider: MockBundleDataProvider!

    override func setUp() {
        super.setUp()
        self.bundleDataProvider = MockBundleDataProvider()
    }

    override func tearDown() {
        super.tearDown()
        self.bundleDataProvider = nil
    }

    func testEmptyDomain_throwsError() {
        bundleDataProvider.error = SiteImageError.noImageInBundle
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: [])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func testInvalidData_throwsError() {
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.invalidData)
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["mozilla"])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func testEmptyData_throwsError() {
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.emptyData)
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["mozilla"])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func testValidData_withoutPath_throwsError() {
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.validData)
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["mozilla"])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func testValidData_returnImage() {
        let expectedImage = mockImage()
        bundleDataProvider.imageToReturn = expectedImage
        bundleDataProvider.pathToReturn = "a/path/to/image"
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.validData)
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["mozilla"])

        do {
            let result = try subject.getImageFromBundle(domain: domain)
            XCTAssertEqual(expectedImage.size, result.size)
        } catch {
            XCTFail("Should have succeeded")
        }
    }

    func testValidData_whenDomainNotPresent_throwsError() {
        bundleDataProvider.imageToReturn = mockImage()
        bundleDataProvider.pathToReturn = "a/path/to/image"
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.validData)
        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["fakedomain"])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func testPartlyValidData() {
        bundleDataProvider.pathToReturn = "a/path/to/image"
        bundleDataProvider.data = generateHTMLData(string: MockBundleData.partlyValidData)

        let subject = DefaultBundleImageFetcher(bundleDataProvider: bundleDataProvider)
        let domain = ImageDomain(bundleDomains: ["google"])

        do {
            _ = try subject.getImageFromBundle(domain: domain)
            XCTFail("Should fail")
        } catch let error as SiteImageError {
            XCTAssertEqual("No image in bundle was found",
                           error.description)
        } catch {
            XCTFail("Should have failed with BundleError type")
        }
    }

    func mockImage() -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 100, height: 100))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
}

private enum MockBundleData {
    static let invalidData = "invalidData"

    static let emptyData = "[]"

    static let validData = """
[{"title": "mozilla", "url": "https://www.mozilla.com.cn/", "image_url": "mozilla-com.png", "background_color": "#000", "domain": "mozilla.com.cn" },{"title": "google","url": "https://www.google.com/","image_url": "google-com.png","background_color": "#FFF","is_multi_region_domain": "true","domain": "google"}]
"""

    static let partlyValidData = """
[{"title": "mozilla", "url": "https://www.mozilla.com.cn/", "image_url": "mozilla-com.png", "background_color": "#000", "domain": "mozilla.com.cn" },{"title": "google","url": "https://www.google.com/","image_url": "google-com.png","background_color": "#FFF","is_multi_region_domain": "true"}]
"""
}

private extension BundleImageFetcherTests {
    func generateHTMLData(string: String) -> Data? {
        return string.data(using: .utf8)
    }
}

// MARK: - MockBundleDataProvider
private class MockBundleDataProvider: BundleDataProvider {
    var data: Data?
    var error: SiteImageError?
    func getBundleData() throws -> Data {
        if let data = data {
            return data
        } else {
            throw error ?? SiteImageError.noImageInBundle
        }
    }

    var pathToReturn: String?
    func getPath(from path: String) -> String? {
        return pathToReturn
    }

    var imageToReturn: UIImage?
    func getBundleImage(from path: String) -> UIImage? {
        return imageToReturn
    }
}
