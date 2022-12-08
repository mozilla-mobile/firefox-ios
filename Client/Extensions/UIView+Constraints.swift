// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIView {
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
}
