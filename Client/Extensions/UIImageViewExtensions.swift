/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

public extension UIImageView {
    public func setIcon(icon: Favicon?, withPlaceholder placeholder: UIImage) {
        if let icon = icon {
            let imageURL = NSURL(string: icon.url)
            self.sd_setImageWithURL(imageURL, placeholderImage: placeholder)
            return
        }
        self.image = placeholder
    }
}