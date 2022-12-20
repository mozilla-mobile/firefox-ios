// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

protocol SiteImageFetcher {
    func getImage(urlStringRequest: String, type: SiteImageType, id: UUID) async -> SiteImageModel
}

class DefaultSiteImageFetcher: SiteImageFetcher {
    private let urlHandler: FaviconURLHandler
    private let imageHandler: ImageHandler

    init(urlHandler: FaviconURLHandler = DefaultFaviconURLHandler(),
         imageHandler: ImageHandler = DefaultImageHandler()) {
        self.urlHandler = urlHandler
        self.imageHandler = imageHandler
    }

    func getImage(urlStringRequest: String, type: SiteImageType, id: UUID) async -> SiteImageModel {
        var imageModel = SiteImageModel(id: id,
                                        expectedImageType: type,
                                        urlStringRequest: urlStringRequest,
                                        siteURL: nil,
                                        domain: nil,
                                        faviconURL: nil,
                                        faviconImage: nil,
                                        heroImage: nil)

        // urlStringRequest possibly cannot be a URL
        if let siteURL = URL(string: urlStringRequest) {
            let domain = generateDomainURL(siteURL: siteURL)
            imageModel.siteURL = siteURL
            imageModel.domain = domain
        }

        do {
            switch type {
            case .heroImage:
                imageModel.heroImage = try await getHeroImage(imageModel: imageModel)
            case .favicon:
                imageModel.faviconImage = await getFaviconImage(imageModel: imageModel)
            }
        } catch {
            // If hero image fails, we return a favicon image
            imageModel.faviconImage = await getFaviconImage(imageModel: imageModel)
        }

        return imageModel
    }

    // MARK: - Private

    private func getHeroImage(imageModel: SiteImageModel) async throws -> UIImage {
        guard let siteURL = imageModel.siteURL,
              let domain = imageModel.domain else { throw SiteImageError.noHeroImage }

        do {
            return try await imageHandler.fetchHeroImage(siteURL: siteURL,
                                                         domain: domain)
        } catch {
            throw error
        }
    }

    private func getFaviconImage(imageModel: SiteImageModel) async -> UIImage {
        guard let domain = imageModel.domain else {
            // If no domain, we generate the favicon from the urlStringRequest
            let domain = ImageDomain(baseDomain: imageModel.urlStringRequest, bundleDomains: [])
            return await imageHandler.fetchFavicon(imageURL: imageModel.faviconURL,
                                                   domain: domain,
                                                   expectedType: imageModel.expectedImageType)
        }

        do {
            // Try to fetch the favicon URL
            let faviconURLImageModel = try await urlHandler.getFaviconURL(site: imageModel)
            return await imageHandler.fetchFavicon(imageURL: faviconURLImageModel.faviconURL,
                                                   domain: domain,
                                                   expectedType: imageModel.expectedImageType)
        } catch {
            // If no favicon URL, generate favicon without it
            return await imageHandler.fetchFavicon(imageURL: imageModel.faviconURL,
                                                   domain: domain,
                                                   expectedType: imageModel.expectedImageType)
        }
    }

    private func generateDomainURL(siteURL: URL) -> ImageDomain {
        let bundleDomains = BundleDomainBuilder().buildDomains(for: siteURL)
        let baseDomain = siteURL.shortDomain ?? siteURL.shortDisplayString
        return ImageDomain(baseDomain: baseDomain, bundleDomains: bundleDomains)
    }
}
