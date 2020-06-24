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
         let titleLabel = self.label
         self.titleLabel?.removeFromSuperview()
         addSubview(titleLabel)

         let imageView = self.imageView!
         let subtitleLabel = self.subtitleLabel
         self.addSubview(subtitleLabel)

         imageView.snp.makeConstraints { make in
             make.centerY.left.equalTo(10)
             make.width.equalTo(TodayUX.copyLinkImageWidth)
         }

         titleLabel.snp.makeConstraints { make in
             make.left.equalTo(imageView.snp.right).offset(10)
             make.trailing.top.equalTo(self)
             make.height.greaterThanOrEqualTo(12)
         }

         subtitleLabel.lineBreakMode = .byTruncatingTail
         subtitleLabel.snp.makeConstraints { make in
             make.bottom.equalTo(self).inset(10)
             make.top.equalTo(titleLabel.snp.bottom)
             make.leading.trailing.equalTo(titleLabel)
             make.height.greaterThanOrEqualTo(10)
         }
     }

     override func setTitle(_ text: String?, for state: UIControl.State) {
         self.label.text = text
         super.setTitle(text, for: state)
     }
}
