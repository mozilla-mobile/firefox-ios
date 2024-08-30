// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Used in HeroImageView and FaviconImageView to update their image using the SiteImageHandler
protocol SiteImageView: UIView {
    var uniqueID: UUID? { get set }
    var imageFetcher: SiteImageHandler { get set }

    /// The URL string representing the currently-displayed image on the view.
    /// This is `nil` if an image has been set manually.
    var currentURLString: String? { get set }
    func updateImage(model: SiteImageModel)
    func setImage(image: UIImage)
    func canMakeRequest(with siteURLString: String?) -> Bool
}

extension SiteImageView {
    func canMakeRequest(with siteURLString: String?) -> Bool {
        guard currentURLString != nil else {
            currentURLString = siteURLString
            return true
        }

        return currentURLString != siteURLString
    }

    func updateImage(model: SiteImageModel) {
        Task { [weak self] in
            let image = await self?.imageFetcher.getImage(model: model)

            await MainActor.run { [weak self] in
                guard let self, let image, uniqueID == model.id else { return }
                setImage(image: image)
            }
        }
    }
}
