// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIView {
    // Wait for contentView bounds to be correct and check if is has been added before
    var shouldAddBlur: Bool {
        guard !bounds.isEmpty else { return false }

        return !subviews.contains(where: { $0 is UIVisualEffectView })
    }

    /// Shortcut to set the view's background color to `.clear`, set the view's
    /// `clipsToBounds` property set to true, and then add a blur effect on the view,
    /// using the desired blur style.
    ///
    /// - Parameter style: The strength of the blur desired
    func addBlurEffectWithClearBackgroundAndClipping(using style: UIBlurEffect.Style) {
        guard !UIAccessibility.isReduceTransparencyEnabled, shouldAddBlur else { return }

        clipsToBounds = true
        backgroundColor = .clear
        addBlurEffect(using: style)
    }

    /// Shortcut to set a blur effect on a view, given a specified style of blur desired.
    ///
    /// - Parameter style: The strength of the blur desired
    func addBlurEffect(using style: UIBlurEffect.Style) {
        guard !UIAccessibility.isReduceTransparencyEnabled else { return }

        let blurEffect = UIBlurEffect(style: style)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.clipsToBounds = true
        blurEffectView.isUserInteractionEnabled = false
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(blurEffectView, at: 0)

        NSLayoutConstraint.activate([
            blurEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurEffectView.topAnchor.constraint(equalTo: topAnchor),
            blurEffectView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func removeVisualEffectView() {
        for subview in self.subviews where subview is UIVisualEffectView {
            subview.removeFromSuperview()
        }
        // Set clipsToBounds to false to make sure shadows will be visible
        clipsToBounds = false
    }

    /// Rounds the requested corners of a view with the provided radius.
    func addRoundedCorners(_ cornersToRound: UIRectCorner, radius: CGFloat) {
        let maskPath = UIBezierPath(roundedRect: bounds,
                                    byRoundingCorners: cornersToRound,
                                    cornerRadii: CGSize(width: radius, height: radius))

        // Create the shape layer and set its path
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
    }

    /// Getting a snapshot from a view using image renderer
    var snapshot: UIImage {
        UIGraphicsImageRenderer(size: bounds.size).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}
