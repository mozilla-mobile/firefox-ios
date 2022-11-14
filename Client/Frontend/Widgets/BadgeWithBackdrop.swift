// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

// Puts a backdrop (i.e. dark highlight) circle on the badged button.
class BadgeWithBackdrop2: UIView {

    struct UX {
        static let backdropAlpha: CGFloat = 0.05
        static let badgeOffset: CGFloat = 10
    }

    // MARK: - Variables
    private var backdrop: UIView
    private var badge: ToolbarBadge
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

        backdrop = BadgeWithBackdrop2.makeCircle(color: backdropCircleColor, size: backdropCircleSize)
        backdrop.isUserInteractionEnabled = false

        super.init(frame: CGRect(width: backdropCircleSize, height: backdropCircleSize))
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ visible: Bool) {
        isHidden = !visible
    }

    func updateTheme(badgeBackgroundColor: UIColor) {
        badge.tintBackground(color: badgeBackgroundColor)
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
        addSubview(backdrop)
        addSubview(badge)

        badge.translatesAutoresizingMaskIntoConstraints = false
        backdrop.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
            backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
            backdrop.widthAnchor.constraint(equalToConstant: backdropCircleSize),
            backdrop.heightAnchor.constraint(equalToConstant: backdropCircleSize),

            badge.centerXAnchor.constraint(equalTo: centerXAnchor, constant: UX.badgeOffset),
            badge.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -UX.badgeOffset),
            badge.widthAnchor.constraint(equalToConstant: badgeSize),
            badge.heightAnchor.constraint(equalToConstant: badgeSize)
        ])
    }
}
