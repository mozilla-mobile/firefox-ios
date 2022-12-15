// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Common

/// Used in HeroImageView and FaviconImageView to update their image using the SiteImageFetcher
protocol SiteImageView: UIView {
    var uniqueID: UUID? { get set }
    var imageFetcher: SiteImageFetcher { get set }

    func setURL(_ urlStringRequest: String, type: SiteImageType)
    func updateImage(url: String, type: SiteImageType, id: UUID)
    func setImage(imageModel: SiteImageModel)

    // Avoid multiple image loading in parallel. Only start a new request if the URL string has changed
    var requestStartedWith: String? { get set }
    func canMakeRequest(with urlStringRequest: String) -> Bool
}

extension SiteImageView {
    func canMakeRequest(with urlStringRequest: String) -> Bool {
        return requestStartedWith != urlStringRequest
    }

    func updateImage(url: String, type: SiteImageType, id: UUID) {
        Task {
            let imageModel = await imageFetcher.getImage(urlStringRequest: url, type: type, id: id)
            guard uniqueID == imageModel.id else { return }

            DispatchQueue.main.async { [weak self] in
                self?.setImage(imageModel: imageModel)
                self?.requestStartedWith = nil
            }
        }
    }
}
