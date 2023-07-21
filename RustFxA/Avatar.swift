// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

open class Avatar {
    open var image: UIImage?
    public let url: URL?

    init(url: URL?) {
        self.url = url

        downloadAvatar(url: url) { image in
            guard let avatarImage = image else {
                self.image = UIImage(named: StandardImageIdentifiers.Large.avatarCircle)
                NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
                return
            }

            self.image = avatarImage
            NotificationCenter.default.post(name: .FirefoxAccountProfileChanged, object: self)
        }
    }

    private func downloadAvatar(url: URL?, completion: @escaping (UIImage?) -> Void) {
        guard let avatarUrl = url else {
            completion(nil)
            return
        }

        GeneralizedImageFetcher().getImageFor(url: avatarUrl) { image in
            completion(image)
        }
    }
}
