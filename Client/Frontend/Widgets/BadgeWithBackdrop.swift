// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// Puts a backdrop (i.e. dark highlight) circle on the badged button.
class BadgeWithBackdrop {
    struct UX {
        static let backdropAlpha: CGFloat = 0.05
        static let badgeOffset: CGFloat = 10
    }

    // MARK: - Variables
    var backdrop: UIView
    var badge: ToolbarBadge
    private let badgeSize: CGFloat
    private let backdropCircleSize: CGFloat
    private let backdropCircleColor: UIColor?

    // MARK: - Initializers
    init(imageName: String,
         imageMask: String = "badge-mask",
         backdropCircleColor: UIColor? = nil,
         backdropCircleSize: CGFloat = 40,
         badgeSize: CGFloat = 20) {
        self.backdropCircleColor = backdropCircleColor
        self.backdropCircleSize = backdropCircleSize
        self.badgeSize = badgeSize

        badge = ToolbarBadge(imageName: imageName, imageMask: imageMask, size: badgeSize)
        badge.isHidden = true

        backdrop = BadgeWithBackdrop.makeCircle(color: backdropCircleColor, size: backdropCircleSize)
        backdrop.isHidden = true
        backdrop.isUserInteractionEnabled = false

        setupLayout()
    }

    func show(_ visible: Bool) {
        badge.isHidden = !visible
        backdrop.isHidden = !visible
    }

    func add(toParent parent: UIView) {
        parent.addSubview(badge)
        parent.addSubview(backdrop)
    }

    func layout(onButton button: UIView) {
        NSLayoutConstraint.activate([
            backdrop.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            backdrop.centerYAnchor.constraint(equalTo: button.centerYAnchor),

            badge.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: UX.badgeOffset),
            badge.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -UX.badgeOffset),
        ])
        button.superview?.sendSubviewToBack(backdrop)
    }

    // MARK: - Private
    private static func makeCircle(color: UIColor?, size: CGFloat) -> UIView {
        let circle = UIView()
        circle.alpha = UX.backdropAlpha
        circle.layer.cornerRadius = size / 2
        circle.backgroundColor = color ?? .black
        return circle
    }

    private func setupLayout() {
        badge.translatesAutoresizingMaskIntoConstraints = false
        backdrop.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backdrop.widthAnchor.constraint(equalToConstant: backdropCircleSize),
            backdrop.heightAnchor.constraint(equalToConstant: backdropCircleSize),

            badge.widthAnchor.constraint(equalToConstant: badgeSize),
            badge.heightAnchor.constraint(equalToConstant: badgeSize)
        ])
    }
}
