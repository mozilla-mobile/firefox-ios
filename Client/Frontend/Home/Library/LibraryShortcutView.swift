// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import UIKit
import Storage
import SDWebImage
import XCGLogger
import SyncTelemetry
import SnapKit

class LibraryShortcutView: UIView {
    lazy var button: UIButton = {
        let button = UIButton()
        button.imageView?.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.layer.borderColor = UIColor(white: 0.0, alpha: 0.1).cgColor
        button.layer.borderWidth = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 6
        return button
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = 70
        return titleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        addSubview(titleLabel)

        self.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(60)
            make.height.equalTo(90)
        }

        button.snp.makeConstraints { make in
            make.size.equalTo(60)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(button.snp.bottom).offset(8)
            make.leading.trailing.centerX.equalToSuperview()
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        button.imageView?.snp.remakeConstraints { make in
            make.size.equalTo(22)
            make.center.equalToSuperview()
        }

        super.layoutSubviews()
    }
}
