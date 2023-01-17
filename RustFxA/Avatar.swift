/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

open class Avatar {
    open var image = Deferred<UIImage>()
    public let url: URL?

    init(url: URL?) {
        self.url = url
        downloadAvatar()
    }

    private func downloadAvatar() {
        guard let url = url else { return }

        DefaultImageLoadingHandler.shared.getImageFromCacheOrDownload(
            with: url,
            limit: ImageLoadingConstants.NoLimitImageSize
        ) { image, error in
            guard error == nil,
                  let image = image
            else {
                self.image.fill(UIImage(named: ImageIdentifiers.placeholderAvatar)!)
                NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
                return
            }

            self.image.fill(image)
            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }
}
