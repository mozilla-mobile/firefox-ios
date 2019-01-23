/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

extension UIImage {
    public func createScaled(size: CGSize) -> UIImage {
        let imageRenderer = UIGraphicsImageRenderer(size: size)
        return imageRenderer.image(actions: { (context) in
            draw(in: CGRect(origin: .zero, size: size))
        })
    }
}
