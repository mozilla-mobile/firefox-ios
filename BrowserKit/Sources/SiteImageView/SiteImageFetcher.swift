// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

protocol SiteImageFetcher {
    func getImage(siteURL: URL, type: SiteImageType, id: UUID) async -> SiteImageModel
}

class DefaultSiteImageFetcher: SiteImageFetcher {
    private let urlHandler: FaviconURLHandler
    private let imageHandler: ImageHandler

    init(urlHandler: FaviconURLHandler = DefaultFaviconURLHandler(),
         imageHandler: ImageHandler = DefaultImageHandler()) {
        self.urlHandler = urlHandler
        self.imageHandler = imageHandler
    }

    func getImage(siteURL: URL, type: SiteImageType, id: UUID) async -> SiteImageModel {
        let domain = generateDomainURL(siteURL: siteURL)
        var imageModel = SiteImageModel(expectedImageType: type,
                                        siteURL: siteURL,
                                        domain: domain,
                                        faviconURL: nil,
                                        faviconImage: nil,
                                        heroImage: nil)

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
        do {
            return try await imageHandler.fetchHeroImage(siteURL: imageModel.siteURL,
                                                         domain: imageModel.domain)
        } catch {
            throw error
        }
    }

    private func getFaviconImage(imageModel: SiteImageModel) async -> UIImage {
        do {
            // Try to fetch the favicon URL
            let faviconURLImageModel = try await urlHandler.getFaviconURL(site: imageModel)
            return await imageHandler.fetchFavicon(imageURL: faviconURLImageModel.faviconURL,
                                                   domain: faviconURLImageModel.domain)
        } catch {
            // If no favicon URL, generate favicon without it
            return await imageHandler.fetchFavicon(imageURL: imageModel.faviconURL,
                                                   domain: imageModel.domain)
        }
    }

    private func generateDomainURL(siteURL: URL) -> String {
        return siteURL.shortDomain ?? siteURL.shortDisplayString
    }
}
