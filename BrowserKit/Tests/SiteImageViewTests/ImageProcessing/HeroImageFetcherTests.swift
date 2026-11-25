// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LinkPresentation
import Network
import TestKit
import XCTest
@testable import SiteImageView

@MainActor
final class HeroImageFetcherTests: XCTestCase {
    private var metadataProvider: MetadataProviderFake!
    private var network: MockHTMLDataRequest!
    private let siteURL = URL(string: "https://www.example.com/page")!

    override func setUp() async throws {
        try await super.setUp()
        metadataProvider = MetadataProviderFake()
        network = MockHTMLDataRequest()
    }

    override func tearDown() async throws {
        metadataProvider = nil
        network = nil
        if #available(iOS 17.0, *) {
            VPNProxySessionProvider.shared.update([])
        }
        try await super.tearDown()
    }

    // MARK: - LPMetadataProvider

    func testHeroImageLoading_whenError_throwsError() async {
        metadataProvider.errorResult = TestError.invalidResult
        let subject = createSubject()
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
        let subject = createSubject()
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
        let subject = createSubject()
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
        let subject = createSubject()
        do {
            let image = try await subject.fetchHeroImage(from: URL(string: "www.example.com")!,
                                                         metadataProvider: metadataProvider)
            XCTAssertNotNil(image)
            XCTAssertEqual(network.fetchDataForURLCount, 0)
        } catch {
            XCTFail("Should have succeed with image")
        }
    }

    // MARK: - VPN proxy active

    func testHeroImageLoads_whenProxyActiveAndNoMetaTags_throwsNoHeroImage() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17.0") }
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])
        network.data = html(head: "<title>No image</title>")
        let subject = createSubject()

        do {
            _ = try await subject.fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
            XCTFail("Should have failed")
        } catch let error as SiteImageError {
            XCTAssertEqual(error, .noHeroImage)
            XCTAssertEqual(network.fetchDataForURLCount, 1)
        } catch {
            XCTFail("Should have failed with SiteImageError type")
        }
    }

    func testHeroImageLoads_whenProxyActiveAndNetworkFails_throwsError() async throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17.0") }
        VPNProxySessionProvider.shared.update([makeProxyConfiguration()])
        network.error = SiteImageError.invalidHTML
        let subject = createSubject()

        do {
            _ = try await subject.fetchHeroImage(from: siteURL, metadataProvider: metadataProvider)
            XCTFail("Should have failed")
        } catch let error as SiteImageError {
            XCTAssertEqual(error, .invalidHTML)
        } catch {
            XCTFail("Should have failed with SiteImageError type")
        }
    }

    // MARK: - heroImageURL

    func testHeroImageURL_withOGImage_returnsURL() {
        let data = html(head: #"<meta property="og:image" content="https://cdn.example.com/og.jpg">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/og.jpg")
    }

    func testHeroImageURL_withOGImageURL_returnsURL() {
        let data = html(head: #"<meta property="og:image:url" content="https://cdn.example.com/og.jpg">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/og.jpg")
    }

    func testHeroImageURL_withOGAndTwitterImage_prefersOGRegardlessOfOrder() {
        let data = html(head: """
            <meta name="twitter:image" content="https://cdn.example.com/twitter.jpg">
            <meta property="og:image" content="https://cdn.example.com/og.jpg">
            """)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/og.jpg")
    }

    func testHeroImageURL_withOnlyTwitterImage_returnsTwitterImage() {
        let data = html(head: #"<meta name="twitter:image" content="https://cdn.example.com/twitter.jpg">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/twitter.jpg")
    }

    func testHeroImageURL_withOGImageInNameAttribute_returnsURL() {
        let data = html(head: #"<meta name="og:image" content="https://cdn.example.com/og.jpg">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/og.jpg")
    }

    func testHeroImageURL_withRelativeURL_resolvesAgainstSiteURL() {
        let data = html(head: #"<meta property="og:image" content="/images/og.jpg">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://www.example.com/images/og.jpg")
    }

    func testHeroImageURL_withNonHTTPScheme_skipsToNextTag() {
        let data = html(head: """
            <meta property="og:image" content="data:image/png;base64,AAAA">
            <meta name="twitter:image" content="https://cdn.example.com/twitter.jpg">
            """)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertEqual(url?.absoluteString, "https://cdn.example.com/twitter.jpg")
    }

    func testHeroImageURL_withNoImageTags_returnsNil() {
        let data = html(head: #"<meta property="og:title" content="Example">"#)

        let url = createSubject().heroImageURL(from: data, siteURL: siteURL)

        XCTAssertNil(url)
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> DefaultHeroImageFetcher {
        let subject = DefaultHeroImageFetcher(network: network)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func html(head: String) -> Data {
        Data("<html><head>\(head)</head><body></body></html>".utf8)
    }

    @available(iOS 17.0, *)
    private func makeProxyConfiguration() -> ProxyConfiguration {
        let hop = ProxyConfiguration.RelayHop(
            http2RelayEndpoint: .url(URL(string: "https://proxy.example.invalid/")!)
        )
        return ProxyConfiguration(relayHops: [hop])
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
// FXIOS-13243: LPMetadataProvider and LPLinkMetadata are not Sendable across boundaries
private final class MetadataProviderFake: LPMetadataProvider, @unchecked Sendable {
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
