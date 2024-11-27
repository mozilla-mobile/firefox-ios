// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import LinkPresentation
@testable import SiteImageView

final class ImageHandlerTests: XCTestCase {
    let siteURL = URL(string: "https://www.mozilla.com")!
    let faviconURL = URL(string: "https://www.mozilla.org/media/img/favicons/mozilla/apple-touch-icon.8cbe9c835c00.png")!

    private var heroImageFetcher: MockHeroImageFetcher!
    private var siteImageCache: MockSiteImageCache!
    private var faviconFetcher: MockFaviconFetcher!
    private var letterImageGenerator: MockLetterImageGenerator!

    override func setUp() {
        super.setUp()
        self.heroImageFetcher = MockHeroImageFetcher()
        self.siteImageCache = MockSiteImageCache()
        self.faviconFetcher = MockFaviconFetcher()
        self.letterImageGenerator = MockLetterImageGenerator()
    }

    override func tearDown() {
        super.tearDown()
        self.heroImageFetcher = nil
        self.siteImageCache = nil
        self.faviconFetcher = nil
        self.letterImageGenerator = nil
    }

    // MARK: - Favicon

    private func createSiteImageModel(resourceURL: URL? = nil,
                                      type: SiteImageType = .favicon) -> SiteImageModel {
        return SiteImageModel(id: UUID(),
                              imageType: type,
                              siteURL: siteURL,
                              siteResource: resourceURL != nil ? .remoteURL(url: resourceURL!) : nil,
                              image: nil)
    }

    func testFavicon_whenImageInCache_returnsCacheImage() async {
        let expectedResult = UIImage()
        siteImageCache.image = expectedResult
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL)

        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(expectedResult, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 1)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 0)
        XCTAssertEqual(siteImageCache.getFromCacheWithType, .favicon)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cacheImageCalled, 0)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testFavicon_whenSiteResourceNil_imageIsInBundle_noCachedImage_returnsBundleImage() async {
        // provide this site url, since the cache key is "google" and default favicons are store with cacheKey as name
        // in bundle
        let siteURL = URL(string: "https://www.google.com")!
        let subject = createSubject()
        let model = SiteImageModel(id: UUID(), imageType: .favicon, siteURL: siteURL)
        let image = await subject.fetchFavicon(imageModel: model)

        let siteImageBundle = Bundle.allBundles.first {
            return $0.bundleIdentifier?.contains("browserkit.SiteImageView.resources") ?? false
        }!
        let expectedImage = UIImage(named: "google", in: siteImageBundle, with: nil)
        XCTAssertEqual(expectedImage, image)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testFavicon_whenSiteResourceNil_imageIsInBundle_cachedImagePresent_returnsBundleImage() async {
        let siteURL = URL(string: "https://www.google.com")!
        siteImageCache.image = UIImage()
        let subject = createSubject()
        let model = SiteImageModel(id: UUID(), imageType: .favicon, siteURL: siteURL)
        let image = await subject.fetchFavicon(imageModel: model)

        let siteImageBundle = Bundle.allBundles.first {
            return $0.bundleIdentifier?.contains("browserkit.SiteImageView.resources") ?? false
        }!
        let expectedImage = UIImage(named: "google", in: siteImageBundle, with: nil)
        XCTAssertEqual(expectedImage, image)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testFavicon_whenSiteResourceIsInBundle_returnsBundleImage() async {
        let siteURL = URL(string: "https://www.facebook.com")!
        let subject = createSubject()
        let resource: SiteResource = .bundleAsset(name: "facebook", forRemoteResource: siteURL)
        let model = SiteImageModel(id: UUID(), imageType: .favicon, siteURL: siteURL, siteResource: resource)
        let image = await subject.fetchFavicon(imageModel: model)

        let siteImageBundle = Bundle.allBundles.first {
            return $0.bundleIdentifier?.contains("browserkit.SiteImageView.resources") ?? false
        }!
        let expectedImage = UIImage(named: "facebook", in: siteImageBundle, with: nil)
        XCTAssertEqual(expectedImage, image)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testFavicon_whenNoImages_returnsFallbackLetterFavicon_forHardcodedFaviconURL() async {
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL)
        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 1)

        XCTAssertEqual(siteImageCache.cachedWithType, .favicon)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 1)

        // `cacheKey` will be the `shortDomain` if no `resourceURL` was provided at time of SiteImageModel creation,
        // as it is with sites having hard coded `faviconURL`s
        XCTAssertEqual(model.cacheKey, faviconURL.absoluteString)
        XCTAssertEqual(letterImageGenerator.capturedSiteString, faviconURL.absoluteString)
    }

    func testFavicon_whenNoUrl_returnsFallbackLetterFavicon_noFaviconURL() async {
        let subject = createSubject()
        let site = createSiteImageModel(resourceURL: nil)

        let result = await subject.fetchFavicon(imageModel: site)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cachedWithType, .favicon)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 1)

        XCTAssertEqual(letterImageGenerator.capturedSiteString, siteURL.shortDomain)
    }

    func testFavicon_whenImageFetcherHasImage_returnsFromImageFetcher() async {
        let expectedResult = UIImage()
        faviconFetcher.image = expectedResult
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL)

        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(expectedResult, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 1)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cachedWithType, .favicon)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testFavicon_whenNoImages_returnsFallbackLetterFavicon() async {
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: nil)
        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cachedWithType, .favicon)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 1)

        // `cacheKey` will be the `shortDomain` if no `resourceURL` was provided at time of SiteImageModel creation,
        // as it is with sites having hard coded `faviconURL`s
        XCTAssertEqual(model.cacheKey, siteURL.shortDomain)
        XCTAssertEqual(letterImageGenerator.capturedSiteString, siteURL.shortDomain)
    }

    func testFavicon_whenInternalHomeURL_returnsFallbackLetterFavicon() async {
        let subject = createSubject()
        let model = SiteImageModel(id: UUID(),
                                   imageType: .favicon,
                                   siteURL: URL(string: "internal://local/about/home#panel=0")!,
                                   siteResource: nil,
                                   image: nil)
        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        // Skip faviconFetcher since no faviconURL is provided
        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cachedWithType, .favicon)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 1)

        // ImageHandler has a special site string override for internal strings
        XCTAssertEqual(model.cacheKey, "local")
        XCTAssertEqual(letterImageGenerator.capturedSiteString, "home")
    }

    // MARK: - Hero image

    func testHeroImage_whenImageCached_returnsFromCache() async {
        let expectedResult = UIImage()
        siteImageCache.image = expectedResult
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL,
                                         type: .heroImage)
        do {
            let result = try await subject.fetchHeroImage(imageModel: model)

            XCTAssertEqual(expectedResult, result)

            XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 1)
            XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 0)
            XCTAssertEqual(siteImageCache.getFromCacheWithType, .heroImage)
            XCTAssertEqual(siteImageCache.cacheImageCalled, 0)

            XCTAssertEqual(heroImageFetcher.fetchHeroImageSucceedCalled, 0)
            XCTAssertEqual(heroImageFetcher.fetchHeroImageFailedCalled, 0)
        } catch {
            XCTFail("Should have succeeded with fallback letter image")
        }
    }

    func testHeroImage_whenImageFetcherHasImage_returnsFromImageFetcher() async {
        let expectedResult = UIImage()
        heroImageFetcher.image = expectedResult
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL,
                                         type: .heroImage)
        do {
            let result = try await subject.fetchHeroImage(imageModel: model)

            XCTAssertEqual(expectedResult, result)
            XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
            XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)
            XCTAssertEqual(siteImageCache.cacheImageCalled, 1)

            XCTAssertEqual(heroImageFetcher.fetchHeroImageSucceedCalled, 1)
            XCTAssertEqual(heroImageFetcher.fetchHeroImageFailedCalled, 0)
        } catch {
            XCTFail("Should have succeeded with fallback letter image")
        }
    }

    func testHeroImage_whenNoHeroImage_throwsNoHeroImageError() async {
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL,
                                         type: .heroImage)
        do {
            _ = try await subject.fetchHeroImage(imageModel: model)

            XCTFail("Should have failed with SiteImageError.noHeroImage")
        } catch let error as SiteImageError {
            XCTAssertEqual(error.description, "No hero image was found")
            XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
            XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)
            XCTAssertEqual(siteImageCache.cacheImageCalled, 0)

            XCTAssertEqual(heroImageFetcher.fetchHeroImageSucceedCalled, 0)
            XCTAssertEqual(heroImageFetcher.fetchHeroImageFailedCalled, 1)
        } catch {
            XCTFail("Should have failed with SiteImageError.noHeroImage")
        }
    }

    // MARK: - Hero image fallback

    func testHeroImageFallback_retrievesFromHeroImageCache() async {
        let expectedResult = UIImage()
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL,
                                         type: .heroImage)
        siteImageCache.image = expectedResult

        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 1)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 0)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 0)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cacheImageCalled, 0)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testHeroImageFallback_savesInHeroImageCache() async {
        let expectedResult = UIImage()
        let subject = createSubject()
        let model = createSiteImageModel(resourceURL: faviconURL,
                                         type: .heroImage)
        faviconFetcher.image = expectedResult

        let result = await subject.fetchFavicon(imageModel: model)

        XCTAssertEqual(letterImageGenerator.image, result)

        XCTAssertEqual(siteImageCache.getImageFromCacheSucceedCalled, 0)
        XCTAssertEqual(siteImageCache.getImageFromCacheFailedCalled, 1)

        XCTAssertEqual(faviconFetcher.fetchImageSucceedCalled, 1)
        XCTAssertEqual(faviconFetcher.fetchImageFailedCalled, 0)

        XCTAssertEqual(siteImageCache.cachedWithType, .heroImage)
        XCTAssertEqual(siteImageCache.cacheImageCalled, 1)
        XCTAssertEqual(letterImageGenerator.generateLetterImageCalled, 0)
    }

    func testClearCache() async {
        let subject = createSubject()
        subject.clearCache()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(siteImageCache.clearCacheCalledCount, 1)
    }
}

private extension ImageHandlerTests {
    func createSubject() -> ImageHandler {
        return DefaultImageHandler(imageCache: siteImageCache,
                                   faviconFetcher: faviconFetcher,
                                   letterImageGenerator: letterImageGenerator,
                                   heroImageFetcher: heroImageFetcher)
    }
}

// MARK: - MockHeroImageFetcher
private class MockHeroImageFetcher: HeroImageFetcher {
    var image: UIImage?
    var fetchHeroImageSucceedCalled = 0
    var fetchHeroImageFailedCalled = 0

    func fetchHeroImage(from siteURL: URL,
                        metadataProvider: LPMetadataProvider = LPMetadataProvider()
    ) async throws -> UIImage {
        if let image = image {
            fetchHeroImageSucceedCalled += 1
            return image
        } else {
            fetchHeroImageFailedCalled += 1
            throw SiteImageError.noHeroImage
        }
    }
}

// MARK: - MockSiteImageCache
private class MockSiteImageCache: SiteImageCache {
    var image: UIImage?
    var getImageFromCacheSucceedCalled = 0
    var getImageFromCacheFailedCalled = 0
    var getFromCacheWithType: SiteImageType?
    var cacheImageCalled = 0
    var cachedWithType: SiteImageType?
    var clearCacheCalledCount = 0

    func getImage(cacheKey: String, type: SiteImageType) async throws -> UIImage {
        getFromCacheWithType = type
        if let image = image {
            getImageFromCacheSucceedCalled += 1
            return image
        } else {
            getImageFromCacheFailedCalled += 1
            throw SiteImageError.unableToRetrieveFromCache("")
        }
    }

    func cacheImage(image: UIImage, cacheKey: String, type: SiteImageType) async {
        cacheImageCalled += 1
        cachedWithType = type
    }

    func clear() async {
        clearCacheCalledCount += 1
    }
}

// MARK: - MockFaviconFetcher
private class MockFaviconFetcher: FaviconFetcher {
    var image: UIImage?
    var fetchImageSucceedCalled = 0
    var fetchImageFailedCalled = 0

    func fetchFavicon(from imageURL: URL, imageDownloader: SiteImageDownloader) async throws -> UIImage {
        if let image = image {
            fetchImageSucceedCalled += 1
            return image
        } else {
            fetchImageFailedCalled += 1
            throw SiteImageError.unableToDownloadImage("")
        }
    }
}

// MARK: - MockLetterImageGenerator
private class MockLetterImageGenerator: LetterImageGenerator {
    var image = UIImage()
    var generateLetterImageCalled = 0
    var capturedSiteString: String?

    func generateLetterImage(siteString: String) -> UIImage {
        generateLetterImageCalled += 1
        capturedSiteString = siteString
        return image
    }
}
