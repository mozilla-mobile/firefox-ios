/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit

/* The base favicons protocol */
public protocol Favicons {
    var defaultIcon: UIImage { get }

    func clearFavicons() -> Success
    func addFavicon(icon: Favicon) -> Deferred<Result<Int>>
    func addFavicon(icon: Favicon, forSite site: Site) -> Deferred<Result<Int>>
}
