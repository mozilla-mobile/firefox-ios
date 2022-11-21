// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit

/// The base favicons protocol. To be deprecated soon, do not use for new code
public protocol Favicons {
    func getFaviconImage(forSite site: Site) -> Deferred<Maybe<UIImage>>
}
