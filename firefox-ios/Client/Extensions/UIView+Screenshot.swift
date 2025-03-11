// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol Screenshotable {
    func screenshot(quality: CGFloat) -> UIImage?
}

extension UIView: Screenshotable {
    /// Takes a screenshot of the view with the given aspect ratio.
    /// An aspect ratio of 0 means capture the entire view.
    func screenshot(quality: CGFloat = 1) -> UIImage? {
        return screenshot(frame.size, offset: nil, quality: quality)
    }

    /// Takes a screenshot of the view with the given size.
    private func screenshot(_ size: CGSize, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        guard 0...1 ~= quality else { return nil }

        let offset = offset ?? .zero

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale * quality)
        drawHierarchy(in: CGRect(origin: offset, size: frame.size), afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }
}
