// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

extension UIView {
    /**
     * Takes a screenshot of the view with the given size.
     */
    func screenshot(_ size: CGSize, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
        assert(0...1 ~= quality)

        let offset = offset ?? .zero

        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale * quality)
        drawHierarchy(in: CGRect(origin: offset, size: frame.size), afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    /**
     * Takes a screenshot of the view with the given aspect ratio.
     * An aspect ratio of 0 means capture the entire view.
     */
    func screenshot(_ aspectRatio: CGFloat = 0, offset: CGPoint? = nil, quality: CGFloat = 1) -> UIImage? {
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
    @objc func clone() -> UIView {
        let data = NSKeyedArchiver.archivedData(withRootObject: self)
        return NSKeyedUnarchiver.unarchiveObject(with: data) as! UIView
    }

    /**
     * Rounds the requested corners of a view with the provided radius.
     */
    func addRoundedCorners(_ cornersToRound: UIRectCorner, radius: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: cornersToRound,
                                    cornerRadii: CGSize(width: radius, height: radius))

        // Create the shape layer and set its path
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }

    /// Makes the edge constraints (`topAnchor`, `bottomAnchor`, `leadingAnchor`, `trailingAnchor`) of a view equaled to the edge constraints of another view.
    /// - Parameters:
    ///   - view: The view that we are constraining the current view's edges to.
    ///   For example : `currentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true`
    ///   - padding: An equal amount of spacing between each edge of the current view  and `view`.
    ///   In a superview and subview relationship, `padding` is the equal space that surrounds the subview inside of the superview.
    func edges(equalTo view: UIView, padding: CGFloat = 0) {
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }

    /// Makes the center x and y anchors of a view equaled to the center x and y anchors of another view.
    /// - Parameter view: The view that we're constraining the current view's center anchors to.
    /// For example : `currentView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true`
    func center(equalTo view: UIView) {
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /**
     This allows us to find the view in a current view hierarchy that is currently the first responder
     */
    static func findSubViewWithFirstResponder(_ view: UIView) -> UIView? {
        let subviews = view.subviews
        if subviews.isEmpty {
            return nil
        }
        for subview: UIView in subviews {
            if subview.isFirstResponder {
                return subview
            }
            return findSubViewWithFirstResponder(subview)
        }
        return nil
    }

    /// Shortcut to set the view's background colour to `.clear`, set the view's
    /// `clipsToBounds` property set to true, and then add a blur effect on the view,
    /// using the desired blur style.
    ///
    /// - Parameter style: The strength of the blur desired
    func addBlurEffectWithClearBackgroundAndClipping(using style: UIBlurEffect.Style) {
        self.clipsToBounds = true
        self.backgroundColor = .clear
        self.addBlurEffect(using: style)
    }

    /// Shortcut to set a blur effect on a view, given a specified style of blur desired.
    ///
    /// - Parameter style: The strength of the blur desired
    func addBlurEffect(using style: UIBlurEffect.Style) {
        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(blurEffectView)
        self.sendSubviewToBack(blurEffectView)

        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }
}
