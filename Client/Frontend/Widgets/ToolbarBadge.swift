// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ToolbarBadge: UIView {

    // MARK: - Variables
    private let badgeSize: CGFloat
    private let badgeOffset = CGFloat(10)
    private let background: UIImageView
    private let badge: UIImageView

    // MARK: - Initializers
    init(imageName: String, imageMask: String, size: CGFloat) {
        badgeSize = size
        background = UIImageView(image: UIImage(imageLiteralResourceName: imageMask))
        badge = UIImageView(image: UIImage(imageLiteralResourceName: imageName))
        super.init(frame: CGRect(width: badgeSize, height: badgeSize))
        addSubview(background)
        addSubview(badge)
        isUserInteractionEnabled = false

        [background, badge].forEach {
            $0.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View setup
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
