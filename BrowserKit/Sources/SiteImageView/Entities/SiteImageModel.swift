// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

struct SiteImageModel {
    let expectedImageType: SiteImageType
    let siteURL: URL
    let domain: String
    let faviconURL: URL?
    let faviconImage: UIImage?
    let heroImage: UIImage?
}
