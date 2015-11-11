/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import UIKit

class MainHeaderView: UIView {
    let waveView = WaveView()

    init() {
        super.init(frame: CGRectZero)

        addSubview(waveView)

        let descriptionLabel = UILabel()
        descriptionLabel.text = UIConstants.Strings.AppDescription
        descriptionLabel.textColor = UIConstants.Colors.DefaultFont
        descriptionLabel.font = descriptionLabel.font.fontWithSize(14)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = NSTextAlignment.Center
        addSubview(descriptionLabel)

        translatesAutoresizingMaskIntoConstraints = false

        waveView.snp_makeConstraints { make in
            make.top.equalTo(self).offset(10)
            make.leading.trailing.equalTo(self)
            make.height.equalTo(200)
        }

        descriptionLabel.snp_makeConstraints { make in
            make.leading.trailing.equalTo(self).inset(30)

            // Priority hack is needed to avoid conflicting constraints with the cell height.
            // See http://stackoverflow.com/a/25795758
            make.top.equalTo(waveView.snp_bottom).offset(20).priority(999)
            make.bottom.equalTo(self).inset(30).priority(999)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}