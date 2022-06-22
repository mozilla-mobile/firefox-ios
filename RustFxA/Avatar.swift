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

        ImageLoadingHandler.getImageFromCacheOrDownload(with: url, limit: ImageLoadingConstants.NoLimitImageSize) { image, error in
            if error != nil || image == nil {
                self.image.fill(UIImage(named: ImageIdentifiers.placeholderAvatar)!)
            }

            if let image = image {
                self.image.fill(image)
            }

            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }
}
