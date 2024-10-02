// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Account

// Puts a backdrop (i.e. dark highlight) circle on the badged button.
class BadgeWithBackdrop: ThemeApplicable {
    struct UX {
        static let backdropAlpha: CGFloat = 0.05
        static let badgeOffset: CGFloat = 10
        static let backdropCircleSize: CGFloat = 40
        static let badgeSize: CGFloat = 20
    }

    // MARK: - Variables
    var backdrop: UIView
    var badge: ToolbarBadge
    private let backdropCircleSize: CGFloat
    private let isPrivateBadge: Bool

    // MARK: - Initializers
    init(imageName: String,
         imageMask: String = ImageIdentifiers.badgeMask,
         isPrivateBadge: Bool = false,
         backdropCircleSize: CGFloat = UX.backdropCircleSize) {
        self.backdropCircleSize = backdropCircleSize
        self.isPrivateBadge = isPrivateBadge

        badge = ToolbarBadge(imageName: imageName, imageMask: imageMask, size: UX.badgeSize)
        badge.isHidden = true

        backdrop = BadgeWithBackdrop.makeCircle(color: nil, size: backdropCircleSize)
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

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        let circleColor = isPrivateBadge ? theme.colors.layerAccentPrivate: nil
        backdrop = BadgeWithBackdrop.makeCircle(color: circleColor,
                                                size: backdropCircleSize)
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

            badge.widthAnchor.constraint(equalToConstant: UX.badgeSize),
            badge.heightAnchor.constraint(equalToConstant: UX.badgeSize)
        ])
    }
}
