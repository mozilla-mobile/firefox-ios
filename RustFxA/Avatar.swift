/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

open class Avatar {
    open var image: UIImage?
    public let url: URL?

    init(url: URL?) {
        self.url = url
        downloadAvatar { image, error in
            guard error == nil,
                  let image = image
            else {
                self.image = UIImage(named: ImageIdentifiers.placeholderAvatar)
                NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
                return
            }

            self.image = image
            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }

    private func downloadAvatar(completionHandler: @escaping(UIImage?, Error?) -> Void) {
        guard let url = url else {
            completionHandler(nil, ImageLoadingError.unableToFetchImage)
            return
        }

        DispatchQueue.global().async {
            DefaultImageLoadingHandler.shared.getImageFromCacheOrDownload(with: url, limit: ImageLoadingConstants.NoLimitImageSize) { image, error in
                guard error == nil,
                      let image = image
                else {
                    completionHandler(image, error)
                    return
                }

                self.image = image
                completionHandler(image, nil)
            }
        }
    }
}
