// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol Screenshotable {
    func screenshot(quality: CGFloat) -> UIImage?

    func screenshot(bounds: CGRect) -> UIImage?
}

extension UIView: Screenshotable {
    /// Takes a screenshot of the view with a given quality
    /// - Parameters:
    ///   - quality: CGFloat that represents quality of the screenshot.
    ///   The expected value is 0 to 1 and is defaulted to 1
    /// - Returns: The image that represents the screenshot
    func screenshot(quality: CGFloat = 1) -> UIImage? {
        return screenshot(frame.size, offset: nil, quality: quality)
    }

    /// Takes a screenshot of the view by drawing it's content in the provided bounds.
    /// - Parameters:
    ///    - bounds: The area of the view to snapshot
    /// - Returns: The image representing the snapshot of the view in the provided bounds.
    func screenshot(bounds: CGRect) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: bounds.size)

        return renderer.image { context in
            drawHierarchy(
                in: bounds,
                afterScreenUpdates: true
            )
        }
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
