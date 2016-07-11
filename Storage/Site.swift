/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

public protocol Identifiable: Equatable {
    var id: Int? { get set }
}

public func ==<T where T: Identifiable>(lhs: T, rhs: T) -> Bool {
    return lhs.id == rhs.id
}

public enum IconType: Int {
    public func isPreferredTo (_ other: IconType) -> Bool {
        return rank > other.rank
    }

    private var rank: Int {
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

public class Favicon: Identifiable {
    public var id: Int? = nil

    public let url: String
    public let date: Date
    public var width: Int?
    public var height: Int?
    public let type: IconType

    public init(url: String, date: Date = Date(), type: IconType) {
        self.url = url
        self.date = date
        self.type = type
    }
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
public class Site: Identifiable {
    public var id: Int? = nil
    var guid: String? = nil

    public var tileURL: URL {
        return URL(string: url)?.domainURL() ?? URL(string: "about:blank")!
    }

    public let url: String
    public let title: String
     // Sites may have multiple favicons. We'll return the largest.
    public var icon: Favicon?
    public var latestVisit: Visit?
    public let bookmarked: Bool?

    public convenience init(url: String, title: String) {
        self.init(url: url, title: title, bookmarked: false)
    }

    public init(url: String, title: String, bookmarked: Bool?) {
        self.url = url
        self.title = title
        self.bookmarked = bookmarked
    }
}
