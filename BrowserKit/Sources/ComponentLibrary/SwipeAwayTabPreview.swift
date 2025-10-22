// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

public class SwipeAwayTabPreview: UIView {
    let screenShotView: UIImageView = .build()

    public override var transform: CGAffineTransform {
        set {
            screenShotView.transform = newValue
        }
        get {
            return screenShotView.transform
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    public func addImage(image: UIImage) {
        screenShotView.image = image
    }

    func setup() {
        backgroundColor = .black
        screenShotView.backgroundColor = .systemPink
        addSubviews(screenShotView)
        NSLayoutConstraint.activate([
            screenShotView.centerXAnchor.constraint(equalTo: centerXAnchor),
            screenShotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            screenShotView.heightAnchor.constraint(equalToConstant: 300),
            screenShotView.widthAnchor.constraint(equalToConstant: 250)
        ])
        screenShotView.layer.cornerRadius = 10
        screenShotView.image = .checkmark
    }
}

@available(iOS 17.0, *)
#Preview {
    let view = SwipeAwayTabPreview()
    return view
}
