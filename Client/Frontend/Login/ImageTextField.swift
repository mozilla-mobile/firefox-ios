/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ImageTextField: UITextField {
    func setLeftImage(image: UIImage?) {
        if let im = image {
            let imageView = UIImageView(image: im)
            // TODO: We should resize the raw image instead of programmatically scaling it.
            let scale: CGFloat = 0.6
            imageView.frame = CGRectMake(0, 0, im.size.width * scale, im.size.height * scale)
            let padding: CGFloat = 10
            let paddingView = UIView(frame: CGRectMake(0, 0, imageView.bounds.width + padding, imageView.bounds.height))
            imageView.center = paddingView.center
            paddingView.addSubview(imageView)
            leftView = paddingView
            leftViewMode = UITextFieldViewMode.Always
        } else {
            leftView = nil
        }
    }
}
