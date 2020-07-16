/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ButtonWithSublabel: UIButton {
    lazy var subtitleLabel = UILabel()
    lazy var label = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        performLayout()
    }

    fileprivate func performLayout() {
        let buttonImage = self.imageView!
        self.titleLabel?.removeFromSuperview()
        addSubview(self.label)
        addSubview(self.subtitleLabel)
        buttonImage.adjustsImageSizeForAccessibilityContentSizeCategory = true
        buttonImage.contentMode = .scaleAspectFit
        
        buttonImage.snp.makeConstraints { make in
            make.left.centerY.equalTo(10)
            make.width.equalTo(self.label.snp.height)
        }
        self.label.snp.makeConstraints { make in
            make.left.equalTo(buttonImage.snp.right).offset(10)
            make.trailing.top.equalTo(self)
        }
        self.label.numberOfLines = 2
        self.label.lineBreakMode = .byWordWrapping
        label.sizeToFit()
        self.subtitleLabel.lineBreakMode = .byTruncatingTail
        self.subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(self).inset(10)
            make.top.equalTo(self.label.snp.bottom)
            make.leading.trailing.equalTo(self.label)
        }
    }

    override func setTitle(_ text: String?, for state: UIControl.State) {
        self.label.text = text
        super.setTitle(text, for: state)
    }
}
