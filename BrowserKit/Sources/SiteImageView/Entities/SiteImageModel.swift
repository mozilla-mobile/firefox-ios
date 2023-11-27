// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Used to fill in information throughout the lifetime of an image request inside SiteImageView
public struct SiteImageModel {
    /// A unique ID to tie the request to a certain image view
    let id: UUID

    /// The image type expected when making a request
    let expectedImageType: SiteImageType

    /// Represents the website and not the resource
    let siteURLString: String?

    /// URL can be nil in case the urlStringRequest cannot be used to build a URL
    var siteURL: URL?

    /// Used to cache any resources related to this request
    var cacheKey: String = ""

    /// Domain can be nil in case we don't have a siteURL to get the domain from
    var domain: ImageDomain?

    /// The favicon URL scrapped from the webpage, high resolution found at preference
    var faviconURL: URL?

    /// The fetched or generated favicon image
    public var faviconImage: UIImage?

    /// The fetched hero image
    var heroImage: UIImage?

    public init(id: UUID,
                expectedImageType: SiteImageType,
                siteURLString: String? = nil,
                siteURL: URL? = nil,
                cacheKey: String = "",
                faviconURL: URL? = nil,
                faviconImage: UIImage? = nil,
                heroImage: UIImage? = nil) {
        self.id = id
        self.expectedImageType = expectedImageType
        self.siteURLString = siteURLString
        self.siteURL = siteURL
        self.cacheKey = cacheKey
        self.domain = nil
        self.faviconURL = faviconURL
        self.faviconImage = faviconImage
        self.heroImage = heroImage
    }
}
