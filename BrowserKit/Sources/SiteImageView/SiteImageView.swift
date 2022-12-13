// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

/// Used in HeroImageView and FaviconImageView to update their image using the SiteImageFetcher
protocol SiteImageView: UIView {
    var uniqueID: UUID? { get set }
    var imageFetcher: SiteImageFetcher { get set }

    func setURL(_ siteURL: URL, type: SiteImageType)
    func updateImage(url: URL, type: SiteImageType, id: UUID)
    func setImage(imageModel: SiteImageModel)
}

extension SiteImageView {
    func updateImage(url: URL, type: SiteImageType, id: UUID) {
        Task {
            let imageModel = await imageFetcher.getImage(siteURL: url, type: type, id: id)
            guard uniqueID == imageModel.id else { return }

            DispatchQueue.main.async { [weak self] in
                self?.setImage(imageModel: imageModel)
            }
        }
    }
}
