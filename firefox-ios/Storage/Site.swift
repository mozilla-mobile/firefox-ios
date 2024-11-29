// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared
import SiteImageView

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
open class Site: Identifiable {
    open var id: Int?
    open var guid: String?

    open var tileURL: URL {
        return URL(string: url, invalidCharacters: false)?.domainURL ?? URL(string: "about:blank")!
    }

    // i.e. `http://www.example.com/` --> `example`
    open var secondLevelDomain: String? {
        return URL(string: url, invalidCharacters: false)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public var faviconImageCacheKey: String {
        return tileURL.shortDomain ?? tileURL.shortDisplayString
    }
    private var storage: Storage {
        return Storage(resource: faviconResource, title: title, id: id, guid: guid, url: url)
    }

    public let url: String
    public let title: String
    public let faviconResource: SiteResource?
    open var metadata: PageMetadata?
    open var latestVisit: Visit?
    open fileprivate(set) var bookmarked: Bool?
    // Created since to avoid making Sites Codable which involes making also PageMetadata and Visit Codable too
    private struct Storage: Codable {
        let resource: SiteResource?
        let title: String
        let id: Int?
        let guid: String?
        let url: String
    }

    private init(from storage: Storage) {
        self.faviconResource = storage.resource
        self.title = storage.title
        self.url = storage.url
        self.id = storage.id
        self.guid = storage.guid
    }

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false, guid: nil, faviconResource: nil)
    }

    public convenience init(id: Int, url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false, guid: nil, faviconResource: nil)
        self.id = id
    }

    public init(url: String,
                title: String,
                bookmarked: Bool?,
                guid: String? = nil,
                faviconResource: SiteResource? = nil) {
        self.url = url
        self.title = title
        self.bookmarked = bookmarked
        self.guid = guid
        self.faviconResource = faviconResource
    }

    open func setBookmarked(_ bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

    // MARK: - Encode & Decode

    public static func encode(with encoder: JSONEncoder, data: [Site]) throws -> Data {
        let storage = data.map { site in
            return site.storage
        }
        return try encoder.encode(storage)
    }

    public static func decode(from decoder: JSONDecoder, data: Data) throws -> [Site] {
        let storage = try decoder.decode([Storage].self, from: data)
        return storage.map {
            return Site(from: $0)
        }
    }
}

// MARK: - Hashable
extension Site: Hashable {
     public func hash(into hasher: inout Hasher) {
         // The == operator below must match the same requirements as this method
         hasher.combine(id)
         hasher.combine(guid)
         hasher.combine(title)
         hasher.combine(url)
         hasher.combine(faviconResource)
     }

     public static func == (lhs: Site, rhs: Site) -> Bool {
         // The hash method above must match the same requirements as this operator
         return lhs.id == rhs.id
         && lhs.guid == rhs.guid
         && lhs.title == rhs.title
         && lhs.url == rhs.url
         && lhs.faviconResource == rhs.faviconResource
     }
 }
