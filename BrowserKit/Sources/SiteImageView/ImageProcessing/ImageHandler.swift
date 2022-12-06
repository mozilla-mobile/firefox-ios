// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

protocol ImageHandler {
    func fetchFavicon(imageURL: URL, domain: String) async throws -> UIImage
    func fetchHeroImage(siteURL: URL, domain: String) async throws -> UIImage
}

class DefaultImageHandler: ImageHandler {

    init() {}

    func fetchFavicon(imageURL: URL, domain: String) async throws -> UIImage {
        return UIImage()
    }

    func fetchHeroImage(siteURL: URL, domain: String) async throws -> UIImage {
        return UIImage()
    }
}
