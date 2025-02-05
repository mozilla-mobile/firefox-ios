// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LinkPresentation
import XCTest
@testable import SiteImageView

final class HeroImageFetcherTests: XCTestCase {
    private var metadataProvider: MetadataProviderFake!

    override func setUp() {
        super.setUp()
        self.metadataProvider = MetadataProviderFake()
    }

    override func tearDown() {
        super.tearDown()
        self.metadataProvider = nil
    }

    func testHeroImageLoading_whenError_throwsError() async {
        metadataProvider.errorResult = TestError.invalidResult
        let subject = DefaultHeroImageFetcher()
        do {
            _ = try await subject.fetchHeroImage(from: URL(string: "www.example.com")!,
                                                 metadataProvider: metadataProvider)
            XCTFail("Should have failed")
        } catch let error as TestError {
            XCTAssertEqual("A test error",
                           error.description)
        } catch {
            XCTFail("Should have failed with TestError type")
        }
    }

    func testHeroImageLoads_whenEmptyMetadata_throwsError() async {
        let subject = DefaultHeroImageFetcher()
        do {
            _ = try await subject.fetchHeroImage(from: URL(string: "www.example.com")!,
                                                 metadataProvider: metadataProvider)
            XCTFail("Should have failed")
        } catch let error as SiteImageError {
            XCTAssertEqual("Unable to download image with reason: Metadata image provider could not be retrieved.",
                           error.description)
        } catch {
            XCTFail("Should have failed with SiteImageError type")
        }
    }

    func testHeroImageLoads_whenProviderImageError_throwsError() async {
        let providerFake = ItemProviderFake()
        providerFake.errorResult = TestError.invalidResult
        providerFake.imageResult = nil
        metadataProvider.metadataResult.imageProvider = providerFake
        let subject = DefaultHeroImageFetcher()
        do {
            _ = try await subject.fetchHeroImage(from: URL(string: "www.example.com")!,
                                                 metadataProvider: metadataProvider)
            XCTFail("Should have failed")
        } catch let error as SiteImageError {
            XCTAssertEqual("Unable to download image with reason: Optional(A test error)",
                           error.description)
        } catch {
            XCTFail("Should have failed with SiteImageError type")
        }
    }

    func testHeroImageLoads_whenImage_returnsImage() async {
        metadataProvider.metadataResult.imageProvider = ItemProviderFake()
        let subject = DefaultHeroImageFetcher()
        do {
            let image = try await subject.fetchHeroImage(from: URL(string: "www.example.com")!,
                                                         metadataProvider: metadataProvider)
            XCTAssertNotNil(image)
        } catch {
            XCTFail("Should have succeed with image")
        }
    }
}

// MARK: - Helper
private extension HeroImageFetcherTests {
    enum TestError: Error, CustomStringConvertible {
        var description: String { "A test error" }

        case invalidResult
    }
}

// MARK: - MetadataProviderFake
private class MetadataProviderFake: LPMetadataProvider {
    var metadataResult = LPLinkMetadata()
    var errorResult: Error?
    override func startFetchingMetadata(for URL: URL, completionHandler: @escaping (LPLinkMetadata?, Error?) -> Void) {
        completionHandler(metadataResult, errorResult)
    }
}

// MARK: - ItemProviderFake
private  class ItemProviderFake: NSItemProvider {
    var imageResult: UIImage? = UIImage()
    var errorResult: Error?
    override func loadObject(
        ofClass aClass: NSItemProviderReading.Type,
        completionHandler: @escaping (NSItemProviderReading?, Error?) -> Void
    ) -> Progress {
        completionHandler(imageResult, errorResult)
        return Progress()
    }
}
