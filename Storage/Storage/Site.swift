/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol Identifiable {
    var id: Int? { get set }
}

public enum IconType: Int {
    case Icon = 0
    case AppleIcon = 1
    case AppleIconPrecomposed = 2
    case Guess = 3
}

public class Favicon : Identifiable {
    var id: Int? = nil
    var img: UIImage? = nil

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

public class Site : Identifiable {
    var id: Int? = nil
    var guid: String? = nil

    public let url: String
    public let title: String
     // Sites may have multiple favicons. We'll return the largest.
    public var icon: Favicon?

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }
}
