/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

public protocol Identifiable: Equatable {
    var id: Int? { get set }
}

public func ==<T>(lhs: T, rhs: T) -> Bool where T: Identifiable {
    return lhs.id == rhs.id
}

public enum IconType: Int {
    public func isPreferredTo (_ other: IconType) -> Bool {
        return rank > other.rank
    }

    fileprivate var rank: Int {
        switch self {
        case .appleIconPrecomposed:
            return 5
        case .appleIcon:
            return 4
        case .icon:
            return 3
        case .local:
            return 2
        case .guess:
            return 1
        case .noneFound:
            return 0
        }
    }

    case icon = 0
    case appleIcon = 1
    case appleIconPrecomposed = 2
    case guess = 3
    case local = 4
    case noneFound = 5
}

open class Favicon: Identifiable {
    open var id: Int?

    open let url: String
    open let date: Date
    open var width: Int?
    open var height: Int?
    open let type: IconType

    public init(url: String, date: Date = Date(), type: IconType) {
        self.url = url
        self.date = date
        self.type = type
    }
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
open class Site: Identifiable {
    open var id: Int?
    var guid: String?

    open var tileURL: URL {
        return URL(string: url)?.domainURL ?? URL(string: "about:blank")!
    }

    open let url: String
    open let title: String
    open var metadata: PageMetadata?
     // Sites may have multiple favicons. We'll return the largest.
    open var icon: Favicon?
    open var latestVisit: Visit?
    open fileprivate(set) var bookmarked: Bool?

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false)
    }

    public init(url: String, title: String, bookmarked: Bool?) {
        self.url = url
        self.title = title
        self.bookmarked = bookmarked
    }

    open func setBookmarked(_ bookmarked: Bool) {
        self.bookmarked = bookmarked
    }

}
