/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UIView {
    /**
     * Takes a screenshot of the view with the given size.
     */
    func screenshot(size: CGSize, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        assert(0...1 ~= quality)

        let offset = offset ?? CGPointMake(0, 0)

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.mainScreen().scale * quality)
        drawViewHierarchyInRect(CGRect(origin: offset, size: frame.size), afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /**
     * Takes a screenshot of the view with the given aspect ratio.
     * An aspect ratio of 0 means capture the entire view.
     */
    func screenshot(aspectRatio: CGFloat, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        assert(aspectRatio >= 0)

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

    /* 
     * Performs a deep copy of the view. Does not copy constraints.
     */
    func clone() -> UIView {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        return NSKeyedUnarchiver.unarchiveObjectWithData(data) as! UIView
    }
}