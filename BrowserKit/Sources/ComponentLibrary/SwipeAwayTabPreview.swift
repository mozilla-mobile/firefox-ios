// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public class SwipeAwayTabPreview: UIView {
    public let screenShotView: UIImageView = .build()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    public func addImage(image: UIImage, startingPoint: CGFloat) {
        screenShotView.image = image
        screenShotView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
    }

    public func translate(position: CGPoint) {
        screenShotView.transform = .identity.translatedBy(x: position.x, y: position.y).scaledBy(
            x: 0.6,
            y: 0.6
        )
    }

    public func restore() {
        screenShotView.transform = .identity
    }

    public func tossPreview() {
        screenShotView.transform = .identity.translatedBy(x: 0, y: -500).scaledBy(
            x: 0.6,
            y: 0.6
        )
    }

    func setup() {
        if #available(iOS 26.0, *) {
            let background = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
            addSubview(background)
            background.pinToSuperview()
        }

        addSubviews(screenShotView)
        NSLayoutConstraint.activate([
            screenShotView.topAnchor.constraint(equalTo: topAnchor),
            screenShotView.leadingAnchor.constraint(equalTo: leadingAnchor),
            screenShotView.trailingAnchor.constraint(equalTo: trailingAnchor),
            screenShotView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        screenShotView.layer.cornerRadius = 55.0
        screenShotView.layer.masksToBounds = true
        screenShotView.clipsToBounds = true
        screenShotView.contentMode = .scaleAspectFill
        screenShotView.backgroundColor = .red
    }
}

@available(iOS 17.0, *)
#Preview {
    let view = SwipeAwayTabPreview()
    return view
}
