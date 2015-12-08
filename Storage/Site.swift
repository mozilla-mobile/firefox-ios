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
    public func isPreferredTo (other: IconType) -> Bool {
        return rank > other.rank
    }

    private var rank: Int {
        switch self {
        case .AppleIconPrecomposed:
            return 5
        case .AppleIcon:
            return 4
        case .Icon:
            return 3
        case .Local:
            return 2
        case .Guess:
            return 1
        case .NoneFound:
            return 0
        }
    }

    case Icon = 0
    case AppleIcon = 1
    case AppleIconPrecomposed = 2
    case Guess = 3
    case Local = 4
    case NoneFound = 5
}

public class Favicon: Identifiable {
    public var id: Int? = nil

    public let url: String
    public let date: NSDate
    public var width: Int?
    public var height: Int?
    public let type: IconType

    public init(url: String, date: NSDate = NSDate(), type: IconType) {
        self.url = url
        self.date = date
        self.type = type
    }
}

// TODO: Site shouldn't have all of these optional decorators. Include those in the
// cursor results, perhaps as a tuple.
public class Site : Identifiable {
    public var id: Int? = nil
    var guid: String? = nil

    public let url: String
    public let title: String
     // Sites may have multiple favicons. We'll return the largest.
    public var icon: Favicon?
    public var latestVisit: Visit?

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
