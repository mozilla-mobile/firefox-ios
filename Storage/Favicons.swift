/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Deferred

/* The base favicons protocol */
public protocol Favicons {
    func clearAllFavicons() -> Success

    /**
     * Returns the ID of the added favicon.
     */
    func addFavicon(_ icon: Favicon) -> Deferred<Maybe<Int>>

    /**
     * Returns the ID of the added favicon.
     */
    func addFavicon(_ icon: Favicon, forSite site: Site) -> Deferred<Maybe<Int>>
}
