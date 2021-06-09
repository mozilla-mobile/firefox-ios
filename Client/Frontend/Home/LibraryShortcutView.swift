/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import SnapKit

class LibraryShortcutView: UIView {
    static let spacing: CGFloat = 15

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(self).offset(-LibraryShortcutView.spacing)
            make.height.equalTo(self.snp.width).offset(-LibraryShortcutView.spacing)
        }
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.7
        title.lineBreakMode = .byTruncatingTail
        title.font = DynamicFontHelper.defaultHelper.SmallSizeRegularWeightAS
        title.textAlignment = .center
        title.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(5)
            make.leading.trailing.equalToSuperview()
        }
        button.imageView?.contentMode = .scaleToFill
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: LibraryShortcutView.spacing)
        button.tintColor = .white
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        button.layer.cornerRadius = (self.frame.width - LibraryShortcutView.spacing) / 2
        super.layoutSubviews()
    }
}
