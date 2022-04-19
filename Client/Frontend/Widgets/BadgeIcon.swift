// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

// Puts a backdrop (i.e. dark highlight) circle on the badged button.
class BadgeWithBackdrop {
    let badge: ToolbarBadge
    var backdrop: UIView
    private let backdropCircleSize: CGFloat
    private let backdropCircleColor: UIColor?
    static let backdropAlpha = CGFloat(0.05)

    private static func makeCircle(color: UIColor?, size: CGFloat) -> UIView {
        let circle = UIView()
        circle.alpha = BadgeWithBackdrop.backdropAlpha
        circle.layer.cornerRadius = size / 2
        if let c = color {
            circle.backgroundColor = c
        } else {
            circle.backgroundColor = .black
        }
        return circle
    }

    init(imageName: String, imageMask: String = "badge-mask", backdropCircleColor: UIColor? = nil, backdropCircleSize: CGFloat = 40, badgeSize: CGFloat = 20) {
        self.backdropCircleColor = backdropCircleColor
        self.backdropCircleSize = backdropCircleSize
        badge = ToolbarBadge(imageName: imageName, imageMask: imageMask, size: badgeSize)
        badge.isHidden = true
        backdrop = BadgeWithBackdrop.makeCircle(color: backdropCircleColor, size: backdropCircleSize)
        backdrop.isHidden = true
        backdrop.isUserInteractionEnabled = false
    }

    func add(toParent parent: UIView) {
        parent.addSubview(badge)
        parent.addSubview(backdrop)
    }

    func layout(onButton button: UIView) {
        badge.layout(onButton: button)
        backdrop.snp.makeConstraints { make in
            make.center.equalTo(button)
            make.size.equalTo(backdropCircleSize)
        }
        button.superview?.sendSubviewToBack(backdrop)
    }

    func show(_ visible: Bool) {
        badge.isHidden = !visible
        backdrop.isHidden = !visible
    }
}
