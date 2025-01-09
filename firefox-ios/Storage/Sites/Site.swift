// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

public enum SiteType: Equatable, Codable, Hashable {
    case basic
    case suggestedSite(SuggestedSiteInfo)
    case sponsoredSite(SponsoredSiteInfo)
    case pinnedSite(PinnedSiteInfo)

    // MARK: - Helpers

    public var isPinnedSite: Bool {
        switch self {
        case .pinnedSite:
            return true
        default:
            return false
        }
    }

    public var isSponsoredSite: Bool {
        switch self {
        case .sponsoredSite:
            return true
        default:
            return false
        }
    }

    public var isSuggestedSite: Bool {
        switch self {
        case .suggestedSite:
            return true
        default:
            return false
        }
    }
}

public struct Site: Identifiable, Hashable, Equatable, Codable {
    public let id: Int
    public let url: String
    public let title: String
    public let type: SiteType

    // MARK: - Other information
    public var faviconResource: SiteImageView.SiteResource?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    // MARK: - Getters

    // Returns the tile's URL.
    public var tileURL: URL {
        switch type {
        case .suggestedSite:
            return URL(string: url, invalidCharacters: false) ?? URL(string: "about:blank")!
        default:
            return URL(string: url, invalidCharacters: false)?.domainURL ?? URL(string: "about:blank")!
        }
    }

    /// Gets the second level domain (i.e. `http://www.example.com/` --> `example`).
    public var secondLevelDomain: String? {
        return URL(string: url, invalidCharacters: false)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public var faviconImageCacheKey: String {
        return tileURL.shortDomain ?? tileURL.shortDisplayString
    }

    // MARK: - Factory Methods

    public static func createBasicSite(
        url: String,
        title: String,
        isBookmarked: Bool? = false,
        faviconResource: SiteImageView.SiteResource? = nil
    ) -> Site {
        var site = Site(id: UUID().hashValue, url: url, title: title, type: .basic)
        site.isBookmarked = isBookmarked
        site.faviconResource = faviconResource
        return site
    }

    public static func createSponsoredSite(url: String, title: String, siteInfo: SponsoredSiteInfo) -> Site {
        return Site(id: UUID().hashValue, url: url, title: title, type: .sponsoredSite(siteInfo))
    }

    public static func createSuggestedSite(
        url: String,
        title: String,
        trackingId: Int,
        faviconResource: SiteImageView.SiteResource? = nil
    ) -> Site {
        let siteInfo = SuggestedSiteInfo(trackingId: trackingId)
        return Site(
            id: UUID().hashValue,
            url: url,
            title: title,
            type: .suggestedSite(siteInfo),
            faviconResource: faviconResource
        )
    }

    public static func createPinnedSite(url: String, title: String, isGooglePinnedTile: Bool) -> Site {
        let siteInfo = PinnedSiteInfo(isGooglePinnedTile: isGooglePinnedTile)
        return Site(id: UUID().hashValue, url: url, title: title, type: .pinnedSite(siteInfo))
    }

    public static func createPinnedSite(fromSite site: Site) -> Site {
        // FIXME can the google pinned tile every go through this?
        let siteInfo = PinnedSiteInfo(isGooglePinnedTile: false)

        return Site(
            id: site.id,
            url: site.url,
            title: site.title,
            type: .pinnedSite(siteInfo),
            faviconResource: site.faviconResource,
            metadata: site.metadata,
            latestVisit: site.latestVisit,
            isBookmarked: site.isBookmarked
        )
    }

    // MARK: - Initializers

    public init(id: Int, url: String, title: String, type: SiteType, faviconResource: SiteImageView.SiteResource? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.type = type
        self.faviconResource = faviconResource
    }

    public init(
        id: Int,
        url: String,
        title: String,
        type: SiteType,
        faviconResource: SiteImageView.SiteResource? = nil,
        metadata: PageMetadata? = nil,
        latestVisit: Visit? = nil,
        isBookmarked: Bool? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.type = type
        self.faviconResource = faviconResource
        self.metadata = metadata
        self.latestVisit = latestVisit
        self.isBookmarked = isBookmarked
    }

    init(fromSite site: Site, withLocalizedURLString urlString: String) {
        self.id = site.id
        self.url = urlString
        self.title = site.title
        self.type = site.type
        self.faviconResource = site.faviconResource
        self.metadata = site.metadata
        self.latestVisit = site.latestVisit
        self.isBookmarked = site.isBookmarked
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

    // FIXME Do we foresee any encoding issues by adding a new key... (mapping from old version of the app)
    // FIXME Is this just used by the widget extension? nbd then... but check the SQL lite DB file too

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(type, forKey: .type)
        try container.encode(faviconResource, forKey: .faviconResource)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(Int.self, forKey: .id)
        let url = try values.decode(String.self, forKey: .url)
        let title = try values.decode(String.self, forKey: .title)
        let faviconResource = try values.decode(SiteImageView.SiteResource.self, forKey: .faviconResource)

        // To migrate old users to the new Site format, we make type optional and assign it to `.basic` if not present
        let type = (try? values.decode(SiteType.self, forKey: .type)) ?? .basic

        self.init(id: id, url: url, title: title, type: type, faviconResource: faviconResource)
    }
}
