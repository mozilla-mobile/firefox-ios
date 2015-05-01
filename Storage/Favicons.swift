/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

/* The base favicons protocol */
// TODO: Deferred, make this less generic.
public protocol Favicons {
    var defaultIcon: UIImage { get }

    func clearFavicons() -> Success
    func addFavicon(icon: Favicon, forSite site: Site) -> Success
}

// TODO: rip this back out.
public class MockFavicons: Favicons {
    public init() {}

    lazy public var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    public func clearFavicons() -> Success {
        return succeed()
    }

    public func addFavicon(icon: Favicon, forSite site: Site) -> Success {
        return succeed()
    }
}
