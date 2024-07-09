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

    /// The URL for the current in-flight request (if any). This is distinct from the `currentURLString`
    /// because it is possible for us to have already requested a remote asset while the image view is
    /// updated for a different image (or nil, for a manual image). In that case if the image view is
    /// once again set to the url for the in-flight request, we should not re-request the same asset.
    var currentInFlightURLString: String? { get set }

    func updateImage(site: SiteImageModel)
    func setImage(imageModel: SiteImageModel)
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

    func hasInFlightRequest(for urlString: String?) -> Bool {
        guard let url1 = urlString, let url2 = currentInFlightURLString else { return false }
        return url1.compare(url2, options: .caseInsensitive) == .orderedSame
    }

    func updateImage(site: SiteImageModel) {
        self.layer.borderWidth = 5
        self.layer.borderColor = UIColor.green.cgColor
        print("DBG: SiteImageView.updateImage()")

        let siteString = site.siteURLString
        guard !hasInFlightRequest(for: siteString) else { return }
        currentInFlightURLString = siteString

        Task {
            let imageModel = await imageFetcher.getImage(site: site)

            DispatchQueue.main.async { [weak self] in
                guard let self, uniqueID == imageModel.id else { return }
                if currentInFlightURLString == siteString {
                    currentInFlightURLString = nil // Clear in-flight state for completed request.
                }
                setImage(imageModel: imageModel)
            }
        }
    }
}
