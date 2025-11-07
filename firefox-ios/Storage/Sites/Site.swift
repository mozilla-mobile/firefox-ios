// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SiteImageView

// TODO: FXIOS-12712 Make Site actually sendable
public struct Site: @unchecked Sendable,
                    Hashable,
                    Equatable,
                    Codable,
                    CustomStringConvertible,
                    CustomDebugStringConvertible {
    public let url: String
    public let title: String
    public let type: SiteType

    public var debugDescription: String {
        // See FXIOS-11335 for context before making updates.
        return "Site (\(type))"
    }

    public var description: String {
        return debugDescription
    }

    // MARK: - Other information
    public var faviconResource: SiteResource?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    // MARK: - Getters

    // Returns the tile's URL.
    public var tileURL: URL {
        switch type {
        case .suggestedSite:
            return URL(string: url) ?? URL(string: "about:blank")!
        default:
            return URL(string: url)?.domainURL ?? URL(string: "about:blank")!
        }
    }

    /// Gets the second level domain (i.e. `http://www.example.com/` --> `example`).
    public var secondLevelDomain: String? {
        return URL(string: url)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public var faviconImageCacheKey: String {
        return tileURL.shortDomain ?? tileURL.shortDisplayString
    }

    // MARK: - Factory Methods

    public static func createBasicSite(
        url: String,
        title: String,
        isBookmarked: Bool? = false,
        faviconResource: SiteResource? = nil
    ) -> Site {
        var site = Site(url: url, title: title, type: .basic)
        site.isBookmarked = isBookmarked
        site.faviconResource = faviconResource
        return site
    }

    public static func createSponsoredSite(url: String, title: String, siteInfo: SponsoredSiteInfo) -> Site {
        return Site(url: url, title: title, type: .sponsoredSite(siteInfo))
    }

    public static func createSuggestedSite(
        id: Int? = nil,
        url: String,
        title: String,
        trackingId: Int,
        faviconResource: SiteResource? = nil
    ) -> Site {
        let siteInfo = SuggestedSiteInfo(trackingId: trackingId)
        return Site(
            url: url,
            title: title,
            type: .suggestedSite(siteInfo),
            faviconResource: faviconResource
        )
    }

    public static func createPinnedSite(
        url: String,
        title: String,
        isGooglePinnedTile: Bool,
        faviconResource: SiteResource? = nil
    ) -> Site {
        let siteInfo = PinnedSiteInfo(isGooglePinnedTile: isGooglePinnedTile)
        return Site(
            url: url,
            title: title,
            type: .pinnedSite(siteInfo),
            faviconResource: faviconResource
        )
    }

    /// Note: This *copies* the pre-existing Site's ID.
    public static func createPinnedSite(fromSite site: Site, isGooglePinnedTile: Bool = false) -> Site {
        let siteInfo = PinnedSiteInfo(isGooglePinnedTile: isGooglePinnedTile)

        return Site(
            url: site.url,
            title: site.title,
            type: .pinnedSite(siteInfo),
            faviconResource: site.faviconResource,
            metadata: site.metadata,
            latestVisit: site.latestVisit,
            isBookmarked: site.isBookmarked
        )
    }

    /// Note: This *copies* the pre-existing Site's ID.
    public static func copiedFrom(site: Site, withLocalizedURLString urlString: String) -> Site {
        return Site(
            url: urlString,
            title: site.title,
            type: site.type,
            faviconResource: site.faviconResource,
            metadata: site.metadata,
            latestVisit: site.latestVisit,
            isBookmarked: site.isBookmarked
        )
    }

    // MARK: - Initializers

    private init(url: String, title: String, type: SiteType, faviconResource: SiteResource? = nil) {
        self.url = url
        self.title = title
        self.type = type
        self.faviconResource = faviconResource
    }

    private init(
        url: String,
        title: String,
        type: SiteType,
        faviconResource: SiteResource? = nil,
        metadata: PageMetadata? = nil,
        latestVisit: Visit? = nil,
        isBookmarked: Bool? = nil
    ) {
        self.url = url
        self.title = title
        self.type = type
        self.faviconResource = faviconResource
        self.metadata = metadata
        self.latestVisit = latestVisit
        self.isBookmarked = isBookmarked
    }

    // MARK: - Helpers

    public var isPinnedSite: Bool {
        return type.isPinnedSite
    }

    public var isSponsoredSite: Bool {
        return type.isSponsoredSite
    }

    public var isSuggestedSite: Bool {
        return type.isSuggestedSite
    }

    // MARK: - Encode & Decode
    // We manually implement the codable methods as we don't need to encode `PageMetadata` and `Visit` information.

    public enum CodingKeys: String, CodingKey {
        case id
        case url
        case title
        case type
        case faviconResource = "resource"
    }

    /// We only need to encode/decode Sites for the Widget Extension. The Widget extension only needs a subset of properties.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)

        // Optional properties
        try container.encode(faviconResource, forKey: .faviconResource)
    }

    /// We only need to encode/decode Sites for the Widget Extension. The Widget extension only needs a subset of properties.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let url = try values.decode(String.self, forKey: .url)
        let title = try values.decode(String.self, forKey: .title)

        // To migrate old users to the new Site format, we make type optional and assign it to `.basic` if not present
        let type = (try? values.decode(SiteType.self, forKey: .type)) ?? .basic

        // Optional properties
        let faviconResource = try? values.decode(SiteResource.self, forKey: .faviconResource)

        self.init(url: url, title: title, type: type, faviconResource: faviconResource)
    }
}
