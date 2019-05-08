/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ToolbarBadge: UIView {
    let badgeSize = CGFloat(16)
    let badgeOffset = CGFloat(10)

    private let background: UIImageView
    private let badge: UIImageView
    init(imageName: String) {
        background = UIImageView(image: UIImage(imageLiteralResourceName: "badge-mask"))
        badge = UIImageView(image: UIImage(imageLiteralResourceName: imageName))
        super.init(frame: CGRect(width: badgeSize, height: badgeSize))

        addSubview(background)
        addSubview(badge)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(onButton button: UIView) {
        snp.remakeConstraints { make in
            make.size.equalTo(badgeSize)
            make.centerX.equalTo(button).offset(badgeOffset)
            make.centerY.equalTo(button).offset(-badgeOffset)
        }
    }

    func tintBackground(color: UIColor) {
        background.tintColor = color
    }
}

// Puts a backdrop (i.e. dark highlight) circle on the badged button.
class BadgeWithBackdrop {
    let badge: ToolbarBadge
    let backdrop: UIView
    static let circleSize = CGFloat(40)
    static let backdropAlpha = CGFloat(0.05)

    static func makeCircle(color: UIColor?) -> UIView {
        let circle = UIView()
        circle.alpha = BadgeWithBackdrop.backdropAlpha
        circle.layer.cornerRadius = circleSize / 2
        if let c = color {
            circle.backgroundColor = c
        } else {
            circle.backgroundColor = .black
        }
        return circle
    }

    init(imageName: String, color: UIColor? = nil) {
        badge = ToolbarBadge(imageName: imageName)
        backdrop = BadgeWithBackdrop.makeCircle(color: color)
        badge.isHidden = true
        backdrop.isHidden = true
    }

    func add(toParent parent: UIView) {
        parent.addSubview(badge)
        parent.addSubview(backdrop)
    }

    func layout(onButton button: UIView) {
        badge.layout(onButton: button)
        backdrop.snp.makeConstraints { make in
            make.center.equalTo(button)
            make.size.equalTo(BadgeWithBackdrop.circleSize)
        }
        button.superview?.sendSubviewToBack(backdrop)
    }

    func show(_ visible: Bool) {
        badge.isHidden = !visible
        backdrop.isHidden = !visible
    }
}
