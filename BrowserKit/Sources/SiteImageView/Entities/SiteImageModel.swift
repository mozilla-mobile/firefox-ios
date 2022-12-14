// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

/// Used to fill in information throughout the lifetime of an image request inside SiteImageView
struct SiteImageModel {
    let id: UUID
    let expectedImageType: SiteImageType
    let siteURL: URL
    let domain: String
    let faviconURL: URL?
    var faviconImage: UIImage?
    var heroImage: UIImage?
}
