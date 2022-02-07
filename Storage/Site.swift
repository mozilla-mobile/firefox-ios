// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

public protocol Identifiable: Equatable {
    var id: Int? { get set }
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: Identifiable {
    return lhs.id == rhs.id
}

open class Favicon: Identifiable {
    open var id: Int?

    public let url: String
    public let date: Date
    open var width: Int?
    open var height: Int?

    public init(url: String, date: Date = Date()) {
        self.url = url
        self.date = date
    }
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
open class Site: Identifiable {
    open var id: Int?
    open var guid: String?

    open var tileURL: URL {
        return URL(string: url)?.domainURL ?? URL(string: "about:blank")!
    }
    
    // i.e. `http://www.example.com/` --> `example`
    open var secondLevelDomain: String? {
        return URL(string: url)?.host?.components(separatedBy: ".").suffix(2).first
    }

    public let url: String
    public let title: String
    open var metadata: PageMetadata?
     // Sites may have multiple favicons. We'll return the largest.
    open var icon: Favicon?
    open var latestVisit: Visit?
    open fileprivate(set) var bookmarked: Bool?

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false, guid: nil)
    }

    public init(url: String, title: String, bookmarked: Bool?, guid: String? = nil) {
        self.url = url
        self.title = title
        self.bookmarked = bookmarked
        self.guid = guid
    }

    open func setBookmarked(_ bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

}

extension Site: Hashable {
     public func hash(into hasher: inout Hasher) {
         hasher.combine(id)
     }

     public static func == (lhs: Site, rhs: Site) -> Bool {
         lhs.url == rhs.url
     }
    
 }
