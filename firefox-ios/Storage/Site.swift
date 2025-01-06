// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

public protocol SitePr: Identifiable, Hashable, Equatable {
    var id: Int { get }
    var url: String { get }
    var title: String { get }

    var faviconResource: SiteResource?  { get set }
    var metadata: PageMetadata?  { get set }
    var latestVisit: Visit?  { get set }
    var isBookmarked: Bool?  { get set }

    // Getter Helpers
    var tileURL: URL { get }
    var secondLevelDomain: String? { get }
    var faviconImageCacheKey: String { get }
}

/// Provides some default implementation of helpers and methods for a Site.
extension SitePr {
    public var tileURL: URL {
        return URL(string: url, invalidCharacters: false)?.domainURL ?? URL(string: "about:blank")!
    }

    // i.e. `http://www.example.com/` --> `example`
    public var secondLevelDomain: String? {
        return URL(string: url, invalidCharacters: false)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public var faviconImageCacheKey: String {
        return tileURL.shortDomain ?? tileURL.shortDisplayString
    }
}

public struct BasicSite: SitePr, Codable {
    public var id: Int
    public var url: String
    public var title: String
    public var faviconResource: SiteImageView.SiteResource?
    public var metadata: PageMetadata?
    public var latestVisit: Visit?
    public var isBookmarked: Bool?

    public init(id: Int, url: String, title: String, faviconResource: SiteImageView.SiteResource? = nil) {
        self.id = id
        self.url = url
        self.title = title
        self.faviconResource = faviconResource
    }

    // MARK: - Encode & Decode
    // We manually implement the codable methods as we don't need to encode `PageMetadata` and `Visit` information.

    public enum CodingKeys: String, CodingKey {
        case id
        case url
        case title
        case faviconResource = "resource"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(title, forKey: .title)
        try container.encode(faviconResource, forKey: .faviconResource)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let id = try values.decode(Int.self, forKey: .id)
        let url = try values.decode(String.self, forKey: .url)
        let title = try values.decode(String.self, forKey: .title)
        let faviconResource = try values.decode(SiteImageView.SiteResource.self, forKey: .faviconResource)

        self.init(id: id, url: url, title: title, faviconResource: faviconResource)
    }
}
