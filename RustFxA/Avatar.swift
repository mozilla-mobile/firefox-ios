/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SDWebImage
import Shared

open class Avatar {
    open var image = Deferred<UIImage>()
    public let url: URL?

    init(url: URL?) {
        self.url = url
        downloadAvatar()
    }

    private func downloadAvatar() {
        SDWebImageManager.shared.loadImage(with: url, options: [.continueInBackground, .lowPriority], progress: nil) { (image, _, error, _, success, _) in
            if let image = image {
                self.image.fill(image)
            } else {
                self.image.fill(UIImage(named: "placeholder-avatar")!)
            }
            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }
}
