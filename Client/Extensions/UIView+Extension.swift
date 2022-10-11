// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

extension UIView {

    /// Convenience function to ease creating new views.
    ///
    /// Calling this function creates a new view with `translatesAutoresizingMaskIntoConstraints`
    /// set to false. Passing in an optional closure to do further configuration of the view.
    ///
    /// - Parameter builder: A function that takes the newly created view.
    ///
    /// Usage:
    /// ```
    ///    private let button: UIButton = .build { button in
    ///        button.setTitle("Tap me!", for state: .normal)
    ///        button.backgroundColor = .systemPink
    ///    }
    /// ```
    static func build<T: UIView>(_ builder: ((T) -> Void)? = nil) -> T {
        let view = T()
        view.translatesAutoresizingMaskIntoConstraints = false
        builder?(view)

        return view
    }

    /// Convenience function to add multiple subviews
    /// - Parameter views: A variadic parameter taking in a list of views to be added.
    ///
    /// Usage:
    /// ```
    ///    view.addSubviews(headerView, contentView, footerView)
    /// ```
    func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }

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
        for subview in self.subviews {
            if subview is UIVisualEffectView { subview.removeFromSuperview() }
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
}
