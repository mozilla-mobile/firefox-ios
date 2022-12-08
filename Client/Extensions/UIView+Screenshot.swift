// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIView {
    /// Takes a screenshot of the view with the given size.
    func screenshot(_ size: CGSize, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        guard 0...1 ~= quality else { return nil }

        let offset = offset ?? .zero

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale * quality)
        drawHierarchy(in: CGRect(origin: offset, size: frame.size), afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /// Takes a screenshot of the view with the given aspect ratio.
    /// An aspect ratio of 0 means capture the entire view.
    func screenshot(_ aspectRatio: CGFloat = 0, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        guard aspectRatio >= 0 else { return nil }

        var size: CGSize
        if aspectRatio > 0 {
            size = CGSize()
            let viewAspectRatio = frame.width / frame.height
            if viewAspectRatio > aspectRatio {
                size.height = frame.height
                size.width = size.height * aspectRatio
            } else {
                size.width = frame.width
                size.height = size.width / aspectRatio
            }
        } else {
            size = frame.size
        }

        return screenshot(size, offset: offset, quality: quality)
    }
}
