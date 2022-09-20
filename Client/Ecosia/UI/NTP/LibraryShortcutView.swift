/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
// Ecosia // import SyncTelemetry
import SnapKit

class LibraryShortcutView: UIView {
    static let spacing: CGFloat = 14
    static let iconSize: CGFloat = 52

    var button = UIButton()
    var title = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(button)
        addSubview(title)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.equalTo(LibraryShortcutView.iconSize)
            make.height.equalTo(LibraryShortcutView.iconSize)
        }
        title.allowsDefaultTighteningForTruncation = true
        title.lineBreakMode = .byTruncatingTail
        title.font = .preferredFont(forTextStyle: .footnote)
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center
        title.numberOfLines = 2
        title.setContentHuggingPriority(.required, for: .vertical)
        title.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(4)
            let maxHeight = title.font.pointSize * 2.6
            make.leading.trailing.equalToSuperview().inset(2).priority(.veryHigh)
            make.height.lessThanOrEqualTo(maxHeight)
        }
        button.imageView?.contentMode = .scaleToFill
        button.layer.cornerRadius = Self.iconSize/2.0
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        button.imageEdgeInsets = UIEdgeInsets(equalInset: Self.spacing)
        button.tintColor = .white
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
