// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIView {
    /// Convenience function to ease creating new views.
    ///
    /// Calling this function creates a new view with `translatesAutoresizingMaskIntoConstraints`
    /// set to false. Passing in an optional closure to do further configuration of the view.
    ///
    /// - Parameters:
    ///   - builder: A function that takes the newly created view.
    ///   - initializer: An optional closure that returns a custom instance of the view.
    ///   If not provided, the default initializer of `T` is used.
    /// - Returns: A newly created and configured view of type `T`.
    ///
    /// Usage:
    /// ```swift
    ///    private let button: UIButton = .build { button in
    ///        button.setTitle("Tap me!", for state: .normal)
    ///        button.backgroundColor = .systemPink
    ///    }
    /// ```
    /// You can also provide a custom initializer:
    /// ```swift
    /// private let customView: CustomView = .build(nil) {
    ///     CustomView(customParameter: "value")
    /// }
    /// ```
    public static func build<T: UIView>(
        _ builder: ((T) -> Void)? = nil,
        _ initializer: (() -> T)? = nil
    ) -> T {
        let view: T = initializer?() ?? T()
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
    public func addSubviews(_ views: UIView...) {
        views.forEach(addSubview)
    }

    /// Convenience utility for pinning a subview to the bounds of its superview.
    public func pinToSuperview() {
        guard let parentView = superview else { return }
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: parentView.topAnchor),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        translatesAutoresizingMaskIntoConstraints = false
    }
}
